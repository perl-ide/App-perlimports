package App::perlimports;

use Moo;

our $VERSION = '0.000001';

use App::perlimports::ExportInspector ();
use Data::Dumper qw( Dumper );
use Data::Printer;
use List::Util qw( any uniq );
use Module::Runtime qw( require_module );
use MooX::HandlesVia qw( has );
use MooX::StrictConstructor;
use Perl::Critic::Utils 1.138 qw( is_function_call is_hash_key );
use Perl::Tidy 20210111 qw( perltidy );
use PPI::Document 1.270 ();
use PPIx::Utils::Classification qw( is_function_call is_hash_key );
use Ref::Util qw( is_plain_hashref );
use Try::Tiny qw( catch try );
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Maybe Object Str);

has _combined_exports => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        _delete_export        => 'delete',
        _has_combined_exports => 'count',
        _is_importable        => 'exists',
        _import_name          => 'get',
    },
    lazy    => 1,
    default => sub { $_[0]->_export_inspector->combined_exports },
);

has _document => (
    is       => 'ro',
    isa      => InstanceOf ['App::perlimports::Document'],
    required => 1,
    init_arg => 'document',
);

has errors => (
    is          => 'rw',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        _add_error => 'push',
        has_errors => 'count',
    },
    init_arg => undef,
    default  => sub { [] },
);

has _export_inspector => (
    is        => 'ro',
    isa       => InstanceOf ['App::perlimports::ExportInspector'],
    predicate => '_has_export_inspector',     # used in test
    lazy      => 1,
    builder   => '_build_export_inspector',
);

has formatted_ppi_statement => (
    is      => 'ro',
    isa     => InstanceOf ['PPI::Statement::Include'],
    lazy    => 1,
    builder => '_build_formatted_ppi_statement',
);

has _ignored_modules => (
    is        => 'ro',
    isa       => ArrayRef,
    init_arg  => 'ignored_modules',
    predicate => '_has_ignored_modules',
);

has _imports => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_imports',
);

has _include => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Statement::Include'],
    init_arg => 'include',
    required => 1,
);

has _is_ignored => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_ignored',
);

has _isa_test_builder_module => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_isa_test_builder_module',
);

has _is_translatable => (
    is            => 'ro',
    isa           => Bool,
    lazy          => 1,
    builder       => '_build_is_translatable',
    documentation => 'Is this a require which can be converted to a use?',
);

has _libs => (
    is       => 'ro',
    isa      => ArrayRef,
    init_arg => 'libs',
    lazy     => 1,
    default  => sub { [ 'lib', 't/lib' ] },
);

has _module_name => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    default => sub { shift->_include->module },
);

has _original_imports => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_original_imports',
);

has _pad_imports => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'pad_imports',
    default  => sub { 1 },
);

has _will_never_export => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->_document->never_exports->{ $self->_module_name }
            || $self->_export_inspector->is_oo_class;
    },
);

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;

    my %args = @args;
    if ( my $source = delete $args{source_text} ) {
        my $doc = PPI::Document->new( \$source );
        my $includes
            = $doc->find( sub { $_[1]->isa('PPI::Statement::Include'); } );
        $args{include} = $includes->[0]->clone;
    }

    return $class->$orig(%args);
};

sub _build_export_inspector {
    my $self = shift;
    return App::perlimports::ExportInspector->new(
        module_name => $self->_module_name,
    );
}

sub _build_isa_test_builder_module {
    my $self = shift;
    $self->_maybe_require_module( $self->_module_name );

## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my $isa_test_builder = any { $_ eq 'Test::Builder::Module' }
    @{ $self->_module_name . '::ISA' };
    use strict;
## use critic

    return $isa_test_builder ? 1 : 0;
}

sub _build_imports {
    my $self = shift;

    # This is not a real symbol, so we should never be looking for it to appear
    # in the code.
    $self->_delete_export('verbose') if $self->_module_name eq 'Carp';

    my %sub_names;
    for my $sub (
        @{
            $self->_document->ppi_document->find(
                sub { $_[1]->isa('PPI::Statement::Sub') }
                )
                || []
        }
    ) {
        my @children = $sub->schildren;
        if ( $children[0] eq 'sub' && $children[1]->isa('PPI::Token::Word') )
        {
            $sub_names{"$children[1]"} = 1;
        }
    }

    #  A used import might be a variable interpolated into quotes.
    my %found;
    for my $var ( keys %{ $self->_document->vars } ) {
        if ( $self->_is_importable($var) ) {
            $found{$var} = 1;
        }
    }

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnfoundImport
    for my $word (
        @{
            $self->_document->ppi_document->find(
                sub {
                    $_[1]->isa('PPI::Token::Word')
                        || $_[1]->isa('PPI::Token::Symbol')
                        || $_[1]->isa('PPI::Token::Label');
                }
                )
                || []
        }
    ) {
        my $found_import;

        # Without the sub name check, we turn
        # use List::Util ();
        # sub any { }
        #
        # into
        #
        # use List::Util qw( any );
        # sub any {}
        next if exists $sub_names{"$word"};

        next if is_hash_key($word);

        # We don't want (for instance) pragma names to be confused with
        # functions.
        #
        # ie:
        # use warnings;
        # use Test::Warnings; # exports warnings()
        if ( $word->parent && $word->parent->isa('PPI::Statement::Include') )
        {
            next;
        }

        next if exists $found{"$word"};

        # If a module exports %foo and we find $foo{bar}, $word->canonical
        # returns $foo and $word->symbol returns %foo
        if (   $word->isa('PPI::Token::Symbol')
            && $self->_is_importable( $word->symbol ) ) {
            $found_import = $word->symbol;
        }

        elsif ( $self->_is_importable("$word") ) {
            $found_import = "$word";
        }

        # Maybe a subroutine ref has been exported. For instance,
        # Getopt::Long exports &GetOptions
        elsif ( is_function_call($word)
            && $self->_is_importable( '&' . $word ) ) {
            $found_import = '&' . "$word";
        }

        # PPI can think that an imported function in a ternary is a label
        # my $foo = $enabled ? GEOIP_MEMORY_CACHE : 0;
        # The content of the $word will be "GEOIP_MEMORY_CACHE :"
        elsif ( $word->isa('PPI::Token::Label') ) {
            if ( $word->content =~ m{^(\w+)} ) {
                my $label = $1;
                if ( $self->_is_importable($label) ) {
                    $found_import = $label;
                    $found{$label}++;
                }
            }
        }

        $found{$found_import}++ if $found_import;
    }

    my @found = map { $self->_import_name($_) } keys %found;

    # Carp exports verbose, which is a symbol which doesn't actually exist.
    # It's basically a flag, so if it's in the import, we'll just preserve it.
    if (
        $self->_module_name eq 'Carp' && (
            any { $_ eq 'verbose' }
            @{ $self->_original_imports }
        )
    ) {
        push @found, 'verbose';
    }

    @found = uniq sort { "\L$a" cmp "\L$b" } @found;
    return \@found;
}

sub _build_original_imports {
    my $self = shift;

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport
    my $expr_qw
        = $self->_include->find(
        sub { $_[1]->isa('PPI::Token::QuoteLike::Words'); } )
        || [];

    my @imports;
    if ( @$expr_qw == 1 ) {
        my $expr  = $expr_qw->[0];
        my @words = $expr_qw->[0]->literal;
        for my $w (@words) {
            next if $w =~ /\A [:\-\+]/x;
            push @imports, $w;
        }
    }

    return \@imports;
}

sub _build_is_ignored {
    my $self = shift;

    # Ignore undef and "no".
    if (
        !$self->_include->type
        || (   $self->_include->type ne 'use'
            && $self->_include->type ne 'require' )
    ) {
        return 1;
    }

    return 1 if $self->_include->pragma;

    if ( $self->_include->type eq 'require' ) {
        return 1 if !$self->_is_translatable;
    }

    # Is this a dependency on a version of Perl?
    # use 5.006;
    # require 5.006;
    return 1 if $self->_include->version;

    my %ignore = (
        'Moo'                    => 1,
        'Moo::Role'              => 1,
        'Moose'                  => 1,
        'namespace::autoclean'   => 1,
        'Test::Needs'            => 1,
        'Test::RequiresInternet' => 1,
        'Types::Standard'        => 1,
    );

    if ( $self->_has_ignored_modules ) {
        for my $name ( @{ $self->_ignored_modules } ) {
            $ignore{$name} = 1;
        }
    }

    return 1 if exists $ignore{ $self->_module_name };

    # This will be rewritten as "use Foo ();"
    return 0 if $self->_will_never_export;

    return 0 if $self->_export_inspector->is_oo_class;

    if (  !$self->_export_inspector->module_is_exporter
        && $self->_export_inspector->is_moose_class ) {
        return 1;
    }

    # This should catch Moose classes
    if ( $self->_maybe_require_module('Moose::Util')
        && Moose::Util::find_meta( $self->_module_name ) ) {
        return 1;
    }

    # This should catch Moo classes
    if ( $self->_maybe_require_module('Class::Inspector') ) {
        return 1
            if any { $_ eq 'Moo::is_class' }
        @{ Class::Inspector->methods(
                $self->_module_name, 'full', 'public'
                )
                || []
        };
    }

    return 0;
}

sub _build_is_translatable {
    my $self = shift;

    return 0 if !$self->_include->type;
    return 0 if $self->_include->type ne 'require';
    return 0 if $self->_module_name eq 'Exporter';

    # We can deal with a top level require.
    # require Foo; can be changed to use Foo ();
    # We don't want to touch requires which are inside any kind of a condition.

    # If there is no parent, then it's likely just a single snippet
    # provided by a text editor. We can process the snippet. If it's part
    # of a larger document and the parent is not a PPI::Document, this
    # would appear not to be a top level require.
    if ( $self->_include->parent
        && !$self->_include->parent->isa('PPI::Document') ) {
        return 0;
    }

    # Postfix conditions are a bit harder to find. If the significant
    # children amount to more than "require Module;", we'll just move on.
    my @children = $self->_include->schildren;

    my $statement = join q{ }, @children[ 0 .. 2 ];
    if ( $statement ne 'require ' . $self->_module_name . ' ;' ) {
        return 0;
    }

    # Any other case of "require Foo;" should be translate to "use Foo ();"
    # as those are functionally equivalent."
    return 1;
}

sub _build_formatted_ppi_statement {
    my $self = shift;

    # The following steps may seem a bit out of order, but we're trying to
    # short circuit if at all possible. That means not building an
    # ExportInspector object unless we really need to.

    # Nothing to do here. Preserve the original statement.
    return $self->_include if $self->_is_ignored;

    # Create this attribute so that we know if there are errors
    if ( !$self->_will_never_export ) {
        $self->_combined_exports;
        if ( $self->_export_inspector->has_errors ) {
            $self->_add_error($_) for @{ $self->_export_inspector->errors };
        }
    }

    # In this case we either have a module which we know will never export
    # symbols or a module which can export but for which we haven't found any
    # imported symbols. In both cases we'll want to rewrite with an empty list
    # of imports.
    if (   $self->_will_never_export
        || $self->_is_translatable
        || ( $self->_has_combined_exports && !@{ $self->_imports } ) ) {
        return $self->_new_include(
            sprintf(
                'use %s %s();', $self->_module_name,
                $self->_include->module_version
                ? $self->_include->module_version . q{ }
                : q{}
            )
        );
    }

    # We don't know if the module exports anything (because it may not be using
    # Exporter) but we also haven't explicitly flagged this as a module which
    # never exports. So basically we can't be correct with confidence, so we'll
    # return the original statement.
    if ( !$self->_has_combined_exports && $self->_include->type ne 'require' )
    {
        return $self->_include;
    }

    my $statement;

    my @args = $self->_include->arguments;

    # Don't touch a do { } block.
    if ( $self->_isa_test_builder_module && @args && $args[0] eq 'do' ) {
        return $self->_include;
    }

    # Do some contortions to turn PPI objects back into a data structure so
    # that we can add or replace an import hash key and then end up with a new
    # list which is sorted on hash keys. This makes the assumption that the
    # same key won't get passed twice. This is pretty gross, but I was too lazy
    # to try to figure out how to do this with PPI and I think it should
    # *mostly* work. I don't like the formatting that Data::Dumper comes up
    # with, so we'll run it through perltidy.

    if (   $self->_isa_test_builder_module
        && @args ) {
        my $all;

        if ( $args[0]->isa('PPI::Token::Word') ) {
            $all = join q{ }, map { "$_" } @args;
        }

        elsif ($args[0]->isa('PPI::Structure::List')
            && $args[0]->braces eq '()' ) {
            for my $child ( $args[0]->children ) {
                $all .= "$child";
            }
        }

        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        my $args;
        my $error;
        try {
            $args = eval( '{' . $all . '}' );
        }
        catch {
            $self->_add_error($_);
            $error = 1;
        };
        ## use critic

        if ( !$error && !is_plain_hashref($args) ) {
            $self->_add_error( 'Not a hashref: ' . np($args) );
            $error = 1;
        }

        # Ignore this line if we can't parse it. This will happen if the arg to
        # test is a do block, for example.
        return $self->_include if $error;

        local $Data::Dumper::Terse         = 1;
        local $Data::Dumper::Indent        = 0;
        local $Data::Dumper::Sortkeys      = 1;
        local $Data::Dumper::Quotekeys     = 0;
        local $Data::Dumper::Useqq         = 0;
        local $Data::Dumper::Trailingcomma = 1;
        local $Data::Dumper::Deparse       = 1;

        $args->{import} = $self->_imports;

        my $dumped = Dumper($args);
        my $formatted;
        if ( $dumped =~ m/^{(.*)}$/ ) {
            $formatted = $1;
        }

        $statement = sprintf(
            keys %$args > 1 ? 'use %s%s( %s );' : 'use %s%s %s;',
            $self->_module_name,
            $self->_include->module_version
            ? q{ } . $self->_include->module_version . q{ }
            : q{ },
            $formatted
        );

        perltidy(
            argv        => '-npro',
            source      => \$statement,
            destination => \$statement
        );
    }

    else {
        my $padding = $self->_pad_imports ? q{ } : q{};
        my $template
            = $self->_isa_test_builder_module
            ? 'use %s%s import => [ qw(%s%s%s) ];'
            : 'use %s%s qw(%s%s%s);';

        $statement = sprintf(
            $template, $self->_module_name,
            (
                $self->_include->module_version
                ? q{ } . $self->_include->module_version
                : q{},
            ),
            $padding,
            join(
                q{ },
                @{ $self->_imports }
            ),
            $padding,
        );
    }

    # Don't deal with Test::Builder classes here to keep is simple for now
    if ( length($statement) > 78 && !$self->_isa_test_builder_module ) {
        $statement = sprintf( "use %s qw(\n", $self->_module_name );
        for ( @{ $self->_imports } ) {
            $statement .= "    $_\n";
        }
        $statement .= ");";
    }

    return $self->_new_include($statement);
}

sub _new_include {
    my $self      = shift;
    my $statement = shift;
    my $doc       = PPI::Document->new( \$statement );
    my $includes
        = $doc->find( sub { $_[1]->isa('PPI::Statement::Include'); } );
    return $includes->[0]->clone;
}

sub _maybe_require_module {
    my $self              = shift;
    my $module_to_require = shift;

    my $success;
    try {
        require_module($module_to_require);
        $success = 1;
    }
    catch {
        $self->_add_error("$module_to_require error. $_");
    };

    return $success;
}

1;

# ABSTRACT: Make implicit imports explicit

=pod

=head1 DESCRIPTION

This distribution provides the L<perlimports> binary, which aims to automate
the cleanup and maintenance of Perl import statements.

=head1 SYNOPSIS

Update a file in place. (Make sure you can revert the file if you need to.)

    perlimports --filename test-data/foo.pl --inplace-edit

If some of your imported modules are in local directories, you can give some
hints as to where to find them:

    perlimports --filename test-data/foo.pl --inplace-edit --libs t/lib,/some/dir/lib

Redirect output to a new file:

    perlimports --filename test-data/foo.pl > foo.new.pl

=head2 VIM

If you're a C<vim> user, you can pipe your import statements to L<perlimports> directly.

    :vnoremap <silent> im :!perlimports --read-stdin --filename '%:p'<CR>

The above statement will allow you to visually select one or more lines of code
and have them updated in place by L<perlimports>. Once you have selected the
code enter C<im> to have your imports (re)formatted.

=head2 MOTIVATION

Many Perl modules helpfully export functions and variables by default. These
provide handy shortcuts when you're writing a quick or small script, but they
can quickly become a maintenance burden as code grows organically. When code
increases in complexity, it leads to greater costs in terms of development time.
Conversely, reducing code complexity can speed up development. This tool aims
to reduce complexity to further this goal.

While importing symbols by default or using export tags provides a convenient
shorthand for getting work done, this shorthand requires the developer to
retain knowledge of these defaults and tags in order to understand the code.
C<perlimports> aims to allow you to develop your code as you see fit, while
still giving you a viable option of tidying your imports automatically. In much
the same way as you might use L<perltidy> to format your code, you can now
automate the process of making your imports easier to understand. Let's look at
some examples.

=over

=item Where is this function defined?

You may come across some code like this:

    use strict;
    use warnings;

    use HTTP::Request::Common;
    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new;
    my $req = $ua->request( GET 'https://metacpan.org/' );
    print $req->content;

Where does C<GET> come from? If you're not familiar with
L<HTTP::Request::Common>, you may not realize that the statement C<use
HTTP::Request::Common> has implicitly imported the functions C<GET>, C<HEAD>,
C<PUT>, C<PATCH>, C<POST> and C<OPTIONS> into to this block of code.

What would happen if we used C<perlimports> to import all needed functions
explicitly? It might look something like this:

    use strict;
    use warnings;

    use HTTP::Request::Common qw( GET );
    use LWP::UserAgent ();

    my $ua = LWP::UserAgent->new;
    my $req = $ua->request( GET 'https://metacpan.org/' );
    print $req->content;

The code above makes it immediately obvious where C<GET> originates, which in
turn makes it easier for us to look up its documentation. It has the added
bonus of also not importing C<HEAD>, C<PUT> or any of the other functions which
L<HTTP::Request::Common> exports by default. So, those functions cannot
unwittingly be used later in the code. This makes for more understandable code
for present day you, future you and any others tasked with reading your code at
some future point.

Keep in mind that this simple act can save much time for developers who are not
intimately familiar with Perl and the default exports of many CPAN modules.

=item Are we even using all of these imports?

Imagine the following import statement

    use HTTP::Status qw(
        is_cacheable_by_default
        is_client_error
        is_error
        is_info
        is_redirect
        is_server_error
        is_success
        status_message
    );

followed by 3,000 lines of code. How do you know if all of these functions are
actually being used? Were they ever used? You can grep all of these function
names manually or you can remove them by trial and error to see what breaks.
This is a doable solution, but it does not scale well to scripts and modules
with many imports or to large code bases with many imports. Having an
unmaintained list of imports is preferable to implicit imports, but it would be
helpful to automate maintaining this list.

L<perlimports> can, in many situations, clean up your import statements and
automate this maintenance burden away. This makes it easier for you to write
clean code, which is easier to understand.

=item Are we even using all of these modules?

In cases where code is implicitly importing from modules or where explicit
imports are not being curated, it can be hard to discover which modules are no
longer being used in a script, module or even a code base. Removing unused
modules from code can lead to gains in performance and decrease in consumption
of resources. Removing entire modules from your code base can decrease the
number of dependencies which you need to manage and decrease friction in your
your deployment process.

C<perlimports> does not remove unused modules for you, but using it to actively
tidy your imports can make this manual process much easier to manage.

=item Enforcing a consistent style

Having a messy list of module imports makes your code harder to read. Imagine
this:

    use Cpanel::JSON::XS;
    use Database::Migrator::Types qw( HashRef ArrayRef Object Str Bool Maybe CodeRef FileHandle RegexpRef );
    use List::AllUtils qw( uniq any );
    use LWP::UserAgent    q{};
    use Try::Tiny qw/ catch     try /;
    use WWW::Mechanize  q<>;

L<perlimports> turns the above list into:

    use Cpanel::JSON::XS ();
    use Database::Migrator::Types qw(
        ArrayRef
        Bool
        CodeRef
        FileHandle
        HashRef
        Maybe
        Object
        RegexpRef
        Str
    );
    use List::AllUtils qw( any uniq );
    use LWP::UserAgent ();
    use Try::Tiny qw( catch try);
    use WWW::Mechanize ();

Where possible, L<perlimports> will enforce a consistent style of parentheses
and will also sort your imports and break up long lines. As mentioned above, if
some imports are no longer in use, C<perlimports> will helpfully remove these
for you.

=item Import tags

Import tags may obscure where symbols are coming from. While import tags
provide a useful shorthand, they can contribute to code complexity by obscuring
the origin of imported symbols. Consider:

    use HTTP::Status qw(:constants :is status_message);

The above line imports the C<status_message()> function as well *some other
things* via C<:constants> and C<:is>. What exactly are these things? We'll need
to read the documentation to know for sure.

C<perlimports> can audit your code and expand the line above to list the
symbols which you are actually importing. So, the line above might now look
something like:

    use HTTP::Status qw(
        HTTP_ACCEPTED
        HTTP_BAD_REQUEST
        HTTP_CONTINUE
        HTTP_I_AM_A_TEAPOT
        HTTP_MOVED_PERMANENTLY
        HTTP_NO_CODE
        HTTP_NOT_FOUND
        HTTP_OK
        HTTP_PAYLOAD_TOO_LARGE
        HTTP_PERMANENT_REDIRECT
        HTTP_RANGE_NOT_SATISFIABLE
        HTTP_REQUEST_ENTITY_TOO_LARGE
        HTTP_REQUEST_RANGE_NOT_SATISFIABLE
        HTTP_REQUEST_URI_TOO_LARGE
        HTTP_TOO_EARLY
        HTTP_UNORDERED_COLLECTION
        HTTP_URI_TOO_LONG
        is_cacheable_by_default
        is_client_error
        is_error
        is_info
        is_redirect
        is_server_error
        is_success
        status_message
    );

This is more verbose, but grepping your code will now reveal to you where
something like C<is_cacheable_by_default> gets defined. You have increased the
lines of code, but you have also reduced complexity.

=back

=head1 METHODS

=head2 formatted_ppi_statement

Returns an L<PPI::Statement::Include> object. This can be stringified into an
import statement or used to replace an existing L<PPI::Statement::Include>.

=head1 CAVEATS

There are lots of shenanigans that Perl modules can get up to. This code will
not find exports for all of those cases, but it should only attempt to rewrite
imports which it knows how to handle. Please file a bug report in all other
cases.

=head1 SEE ALSO

L<Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport>,
L<Perl::Critic::Policy::TooMuchCode::ProhibitUnusedInclude> and
L<Perl::Critic::Policy::TooMuchCode::ProhibitUnusedConstant>

=cut
