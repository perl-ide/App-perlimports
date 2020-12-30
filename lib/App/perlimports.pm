package App::perlimports;

use Moo;

use List::AllUtils qw( any uniq );
use Module::Runtime qw( module_notional_filename require_module );
use Module::Util qw( find_installed );
use Path::Tiny qw( path );
use Perl::Critic::Utils qw( is_function_call );
use PPI::Document ();
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Maybe Str);

has _exports => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_exports',
);

has _filename => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'filename',
    required => 1,
);

has imports => (
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
    builder => '_build__isa_test_builder_module',
);

has module_name => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    builder => '_build_module_name',
);

has _never_exports => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_never_exports',
);

has uses_sub_exporter => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_uses_sub_exporter',
);

has _will_never_export => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->_never_exports->{ $self->module_name };
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

sub _build_module_name {
    my $self = shift;
    return $self->_include->module;
}

sub _build_exports {
    my $self   = shift;
    my $module = $self->module_name;

    return [] if $self->_will_never_export;

    require_module($module);
    $module->import;

## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my @exports
        = uniq( @{ $module . '::EXPORT' }, @{ $module . '::EXPORT_OK' } );
    use strict;
## use critic

    # Moose Type library? And yes, private method bad.
    if ( !@exports && require_module('Class::Inspector') ) {
        if (
            any { $_ eq 'MooseX::Types::Combine::_provided_types' }
            @{ Class::Inspector->methods(
                    $self->module_name, 'full', 'private'
                )
            }
        ) {
            my %types = $self->module_name->_provided_types;
            @exports = keys %types;
        }
    }

    return \@exports;
}

sub _build__isa_test_builder_module {
    my $self = shift;
    $self->_exports;    # ensure module has already been required

## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my $_isa_test_builder = any { $_ eq 'Test::Builder::Module' }
    @{ $self->module_name . '::ISA' };
    use strict;
## use critic

    return $_isa_test_builder;
}

sub _build_imports {
    my $self = shift;

    my $content = path( $self->_filename )->slurp;
    my $doc     = PPI::Document->new( \$content );

    my %exports = map { $_ => 1 } @{ $self->_exports };

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnfoundImport
    my %found;
    for my $word (
        @{
            $doc->find(
                sub {
                    $_[1]->isa('PPI::Token::Word')
                        || $_[1]->isa('PPI::Token::Symbol')
                        || $_[1]->isa('PPI::Token::Label');
                }
                )
                || []
        }
    ) {
        # If a module exports %foo and we find $foo{bar}, $word->canonical
        # returns $foo and $word->symbol returns %foo
        if ( $word->isa('PPI::Token::Symbol')
            && exists $exports{ $word->symbol } ) {
            $found{ $word->symbol }++;
        }

        elsif (
            exists $exports{"$word"}

            # Maybe a subroutine ref has been exported. For instance,
            # Getopt::Long exports &GetOptions
            || ( is_function_call($word) && exists $exports{ '&' . "$word" } )
        ) {
            $found{"$word"}++;
        }

        # PPI can think that an imported function in a ternary is a label
        # my $foo = $enabled ? GEOIP_MEMORY_CACHE : 0;
        # The content of the $word will be "GEOIP_MEMORY_CACHE :"
        elsif ( $word->isa('PPI::Token::Label') ) {
            if ( $word->content =~ m{^(\w+)} ) {
                my $label = $1;
                if ( exists $exports{$label} ) {
                    $found{$label}++;
                }
            }
        }
    }

    my @found = sort { "\L$a" cmp "\L$b" } keys %found;
    return \@found;
}

sub _build_is_ignored {
    my $self = shift;

    if ( $self->_will_never_export
        || @{ $self->imports } ) {
        return 0;
    }

    # We know what FindBin exports, but we need to be smarter about checking
    # for exported variables inside quotes in order for this to be correct.

    my %noop = (
        'FindBin'         => 1,
        'Types::Standard' => 1,
    );

    return 1 if exists $noop{ $self->module_name };

    # Is it a pragma?
    return 1 if $self->_include->pragma;

    return 1 if $self->uses_sub_exporter;

    # This should catch Moose classes
    if (   require_module('Moose::Util')
        && Moose::Util::find_meta( $self->module_name ) ) {
        return 1;
    }

    # This should catch Moo classes
    if ( require_module('Class::Inspector') ) {
        return 1
            if any { $_ eq 'Moo::is_class' }
        @{ Class::Inspector->methods( $self->module_name, 'full', 'public' )
        };
    }

    return 0;
}

# Returns a HashRef of modules which will always be converted to avoid imports.
# This is mostly for speed and a matter of convenience so that we don't have to
# examine modules (like strictly Object Oriented modules) which we know will
# not have anything to export.

sub _build_never_exports {
    my $self = shift;
    return {
        'LWP::UserAgent' => 1,
        'WWW::Mechanize' => 1,
    };
}

sub formatted_import_statement {
    my $self = shift;

    # Cases where we don't want to rewrite the include because we can't be
    # confident that we're doing the right thing.
    if (
        $self->_is_ignored
        || (   !@{ $self->_exports }
            && !$self->_will_never_export )
    ) {
        return $self->_include;
    }

    # In this case we either have a module which can never export or a module
    # which can export but doesn't appear to. In both cases we'll want to
    # rewrite with an empty list of imports.
    if ( $self->_will_never_export
        || !@{ $self->imports } ) {
        return $self->_new_include(
            sprintf(
                'use %s %s();', $self->module_name,
                $self->_include->module_version
                ? $self->_include->module_version . q{ }
                : q{}
            )
        );
    }

    my $template
        = $self->_isa_test_builder_module
        ? 'use %s%s import => [ qw( %s ) ];'
        : 'use %s%s qw( %s );';

    my $statement = sprintf(
        $template, $self->module_name,
        $self->_include->module_version
        ? q{ } . $self->_include->module_version
        : q{}, join q{ },
        @{ $self->imports }
    );

    # Don't deal with Test::Builder classes here to keep is simple for now
    if ( length($statement) > 78 && !$self->_isa_test_builder_module ) {
        $statement = sprintf( "use %s qw(\n", $self->module_name );
        for ( @{ $self->imports } ) {
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

# Stolen from Open::This
sub _maybe_find_local_module {
    my $self          = shift;
    my $module        = $self->module_name;
    my $possible_name = module_notional_filename($module);
    my @dirs
        = exists $ENV{OPEN_THIS_LIBS}
        ? split m{,}, $ENV{OPEN_THIS_LIBS}
        : ( 'lib', 't/lib' );

    for my $dir (@dirs) {
        my $path = path( $dir, $possible_name );
        if ( $path->is_file ) {
            return "$path";
        }
    }
    return undef;
}

# Stolen from Open::This
sub _maybe_find_installed_module {
    my $self = shift;

    # This is a loadable module.  Have this come after the local module checks
    # so that we don't default to installed modules.
    return find_installed( $self->module_name );
}

sub _build_uses_sub_exporter {
    my $self     = shift;
    my $module   = $self->module_name;
    my $filename = $self->_maybe_find_local_module
        || $self->_maybe_find_installed_module;

    if ( !$filename ) {
        print "Cannot find $module\n";
        return;
    }

    my $content = path($filename)->slurp;
    my $doc     = PPI::Document->new( \$content );

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnfoundImport
    my $include_statements = $doc->find(
        sub {
            $_[1]->isa('PPI::Statement::Include') && !$_[1]->pragma;
        }
    ) || [];
    for my $st (@$include_statements) {
        next if $st->schild(0) eq 'no';

        my $included_module = $st->schild(1);
        if ( $included_module eq 'Sub::Exporter' ) {
            return 1;
        }
    }
    return 0;
}

1;

# ABSTRACT: Make implicit imports explicit

=pod

=head1 DESCRIPTION

This distribution provides the C<perlimports> binary, which aims to automate
the cleanup and maintenance of Perl import statements.

=head2 MOTIVATION

Many Perl modules helpfully export functions and variables by default. These
provide handy shortcuts when you're writing a quick or small script, but they
can quickly become a maintenance burden as code grows organically.

=over

=item Problem: Where is this function defined?

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
HTTP::Request::Common> has imported the functions C<GET>, C<HEAD>, C<PUT>,
C<PATCH>, C<POST> and C<OPTIONS> into to this block of code.

=item Solution:

Import all needed functions explicitly.

    use strict;
    use warnings;

    use HTTP::Request::Common qw( GET );
    use LWP::UserAgent ();

    my $ua = LWP::UserAgent->new;
    my $req = $ua->request( GET 'https://metacpan.org/' );
    print $req->content;

The code above makes it immediately obvious where C<GET> originates, which
makes it easier for us to look up its documentation. It has the added bonus of
also not importing C<HEAD>, C<PUT> or any of the other functions which
L<HTTP::Request::Common> exports by default. So, those functions cannot
unwittingly be used later in the code. This makes for more understandable code
for present day you, future you and any others tasked with reading your code at
some future point.

Keep in mind that this simple act can save much time for developers who are not
intimately familiar with Perl and the default exports of many CPAN modules.

=item Problem: Are we using all of these imports?

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
being used? You can grep all of these function names manually or you can remove
them by trial and error to see what breaks. This is a doable solution, but it
does not scale well to scripts and modules with many imports or to large code
bases with many imports. Having an unmaintained list of imports is preferable
to implicit imports, but it would be helpful to automate maintaining this list.

=item Solution: remove unused airports

C<perlimports> can, in many situations, clean up your import statements and
automate this maintenance burden away. This makes it easier for you to write
clean code, which is easier to understand.

=item Problem: Are we using all of these modules?

In cases where code is implicitly importing from modules or where explicit
imports are not being curated, it can be hard to discover which modules are no
longer being used in a script, module or even a code base. Removing unused
modules from code can lead to gains in performance and decrease in consumption
of resources. Removing entire modules from your code base can decrease the
number of dependencies which you need to manage and decrease friction in your
your deployment process.

Actively cleaning up your imports can make this much easier to manage.

=back

=head2 formatted_import_statement

Returns a L<PPI::Statement::Include>. This can be stringified into an import
statement or used to replace an existing L<PPI::Statement::Include>.

=head1 CAVEATS

Does not work with modules using L<Sub::Exporter>.

=head1 SEE ALSO

L<Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport>,
L<Perl::Critic::Policy::TooMuchCode::ProhibitUnusedInclude> and
L<Perl::Critic::Policy::TooMuchCode::ProhibitUnusedConstant>

=cut
