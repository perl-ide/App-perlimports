package App::perlimports::Document;

use Moo;
use utf8;

our $VERSION = '0.000026';

use App::perlimports::Annotations     ();
use App::perlimports::ExportInspector ();
use App::perlimports::Include         ();
use App::perlimports::Sandbox         ();
use File::Basename qw( fileparse );
use List::Util qw( any uniq );
use Module::Runtime qw( module_notional_filename );
use MooX::StrictConstructor;
use Path::Tiny qw( path );
use PPI::Document 1.270 ();
use PPIx::Utils::Classification qw(
    is_function_call
    is_hash_key
    is_method_call
);
use Ref::Util qw( is_plain_arrayref is_plain_hashref );
use Sub::HandlesVia;
use Try::Tiny qw( catch try );
use Types::Standard qw( ArrayRef Bool HashRef InstanceOf Maybe Object Str );

with 'App::perlimports::Role::Logger';

has _annotations => (
    is      => 'ro',
    isa     => InstanceOf ['App::perlimports::Annotations'],
    lazy    => 1,
    default => sub {
        return App::perlimports::Annotations->new(
            ppi_document => shift->ppi_document );
    },
);

has _cache => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'cache',
    lazy     => 1,
    default  => 0,
);

has _cache_dir => (
    is      => 'ro',
    isa     => InstanceOf ['Path::Tiny'],
    lazy    => 1,
    builder => '_build_cache_dir',
);

has _filename => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'filename',
    required => 1,
);

has _ignore_modules => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => 'ignore_modules',
    default  => sub { +{} },
);

has _ignore_modules_pattern => (
    is       => 'ro',
    isa      => ArrayRef [Str],
    init_arg => 'ignore_modules_pattern',
    default  => sub { [] },
);

has includes => (
    is          => 'ro',
    isa         => ArrayRef [Object],
    handles_via => 'Array',
    handles     => {
        all_includes => 'elements',
    },
    lazy    => 1,
    builder => '_build_includes',
);

has _inspectors => (
    is          => 'ro',
    isa         => HashRef [ Maybe [Object] ],
    handles_via => 'Hash',
    handles     => {
        all_inspector_names => 'keys',
        _get_inspector_for  => 'get',
        _has_inspector_for  => 'exists',
        _set_inspector_for  => 'set',
    },
    lazy    => 1,
    default => sub { +{} },
);

has interpolated_symbols => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_interpolated_symbols',
);

has my_own_inspector => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf ['App::perlimports::ExportInspector'] ],
    lazy    => 1,
    builder => '_build_my_own_inspector',
);

has never_exports => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_never_exports',
);

has _never_export_modules => (
    is        => 'ro',
    isa       => ArrayRef [Str],
    init_arg  => 'never_export_modules',
    predicate => '_has_never_export_modules',
);

has original_imports => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        _reset_original_import => 'set',
    },
    lazy    => 1,
    builder => '_build_original_imports',
);

has _padding => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'padding',
    default  => 1,
);

has ppi_document => (
    is      => 'ro',
    isa     => Object,
    lazy    => 1,
    builder => '_build_ppi_document',
);

has possible_imports => (
    is      => 'ro',
    isa     => ArrayRef [Object],
    lazy    => 1,
    builder => '_build_possible_imports',
);

has _ppi_selection => (
    is       => 'ro',
    isa      => Object,
    init_arg => 'ppi_selection',
    lazy     => 1,
    default  => sub { $_[0]->ppi_document },
);

has _preserve_duplicates => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'preserve_duplicates',
    default  => 1,
);

has _preserve_unused => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'preserve_unused',
    default  => 1,
);

has _sub_exporter_export_list => (
    is          => 'ro',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        sub_exporter_export_list => 'elements',
    },
    lazy    => 1,
    builder => '_build_sub_exporter_export_list',
);

has _sub_names => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        is_sub_name => 'exists',
    },
    lazy    => 1,
    builder => '_build_sub_names',
);

has tidied_document => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_tidied_document',
);

has _tidy_whitespace => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'tidy_whitespace',
    lazy     => 1,
    default  => sub { 1 },
);

has _verbose => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'verbose',
    default  => sub { 0 },
);

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;

    my %args = @args;
    if ( my $modules = delete $args{ignore_modules} ) {
        my %modules = map { $_ => 1 } @{$modules};
        $args{ignore_modules} = \%modules;
    }

    if ( my $selection = delete $args{selection} ) {
        $args{ppi_selection} = PPI::Document->new( \$selection );
    }

    return $class->$orig(%args);
};

my %default_ignore = (
    'Carp::Always'                   => 1,
    'Constant::Generate'             => 1,
    'Data::Printer'                  => 1,
    'DDP'                            => 1,
    'Devel::Confess'                 => 1,
    'Encode::Guess'                  => 1,
    'Env'                            => 1,    # see t/env.t
    'Exception::Class'               => 1,
    'Exporter'                       => 1,
    'Exporter::Lite'                 => 1,
    'Feature::Compat::Try'           => 1,
    'Git::Sub'                       => 1,
    'HTTP::Message::PSGI'            => 1,    # HTTP::Request::(to|from)_psgi
    'Mojo::Base'                     => 1,
    'Mojo::Date'                     => 1,
    'Mojolicious::Lite'              => 1,
    'Moo'                            => 1,
    'Moo::Role'                      => 1,
    'Moose'                          => 1,
    'Moose::Exporter'                => 1,
    'Moose::Role'                    => 1,
    'MooseX::NonMoose'               => 1,
    'MooseX::Role::Parameterized'    => 1,
    'MooseX::SemiAffordanceAccessor' => 1,
    'MooseX::StrictConstructor'      => 1,
    'MooseX::TraitFor::Meta::Class::BetterAnonClassNames' => 1,
    'MooseX::Types'                                       => 1,
    'MooX::StrictConstructor'                             => 1,
    'namespace::autoclean'                                => 1,
    'Regexp::Common'                                      => 1,
    'Struct::Dumb'                                        => 1,
    'Sub::Exporter'                                       => 1,
    'Sub::Exporter::Progressive'                          => 1,
    'Sub::HandlesVia'                                     => 1,
    'Syntax::Keyword::Try'                                => 1,
    'Test2::Util::HashBase'                               => 1,
    'Test::Exception'                                     => 1,
    'Test::Needs'                                         => 1,
    'Test::Number::Delta'                                 => 1,
    'Test::Pod'                                           => 1,
    'Test::Pod::Coverage'                                 => 1,
    'Test::Requires::Git'                                 => 1,
    'Test::RequiresInternet'                              => 1,
    'Test::Warnings'                                      => 1,
    'Test::Whitespaces'                                   => 1,
    'Test::XML'                                           => 1,
    'Types::Standard'                                     => 1,
    'URI::QueryParam'                                     => 1,
);

# Funky stuff could happen with inner packages.
sub _build_my_own_inspector {
    my $self = shift;
    my $pkgs
        = $self->ppi_document->find(
        sub { $_[1]->isa('PPI::Statement::Package') && $_[1]->file_scoped } );

    if ( !$pkgs || $pkgs->[0]->namespace eq 'main' ) {
        return;
    }

    my $pkg = $pkgs->[0];

    # file_scoped() doesn't seem to be very reliable, so let's just try a crude
    # check to see if this is a package we might actually find on disk before
    # we try to require it.
    my $notional_file
        = fileparse( module_notional_filename( $pkg->namespace ) );
    my $provided_file = fileparse( $self->_filename );
    return unless $notional_file eq $provided_file;

    return App::perlimports::ExportInspector->new(
        logger      => $self->logger,
        module_name => $pkg->namespace,
    );
}

sub _build_includes {
    my $self = shift;

    # version() returns a value if this a dependency on a version of Perl, e.g
    # use 5.006;
    # require 5.006;
    #
    # We check for type so that we can filter out undef types or "no".

    return $self->_ppi_selection->find(
        sub {
            $_[1]->isa('PPI::Statement::Include')
                && !$_[1]->pragma     # no pragmas
                && !$_[1]->version    # Perl version requirement
                && $_[1]->type
                && ( $_[1]->type eq 'use'
                || $_[1]->type eq 'require' )
                && !$self->_is_ignored( $_[1] )
                && !$self->_has_import_switches( $_[1]->module );
        }
    ) || [];
}

sub _build_possible_imports {
    my $self   = shift;
    my $before = $self->ppi_document->find(
        sub {
                   $_[1]->isa('PPI::Token::Word')
                || $_[1]->isa('PPI::Token::Symbol')
                || $_[1]->isa('PPI::Token::Label')
                || $_[1]->isa('PPI::Token::Prototype');
        }
    ) || [];

    my @after;
    for my $word ( @{$before} ) {

        # Without the sub name check, we accidentally turn
        # use List::Util ();
        # sub any { }
        #
        # into
        #
        # use List::Util qw( any );
        # sub any {}
        next if $self->is_sub_name("$word");

        my $isa_symbol = $word->isa('PPI::Token::Symbol');

        next if !$isa_symbol && is_method_call($word);

        # A hash key might, for example, be a variable.
        if (
            !$isa_symbol
            && !(
                   $word->statement
                && $word->statement->isa('PPI::Statement::Variable')
            )
            && is_hash_key($word)
        ) {
            next;
        }

        push @after, $word;
    }

    return \@after;
}

sub _build_ppi_document {
    my $self = shift;
    return PPI::Document->new( $self->_filename );
}

# Create a key for every included module.
# use Carp;
# use Data::Dumper qw( Dumper );
# use POSIX ();
#
# becomes:
#
# {
#     Carp => undef,
#     'Data::Dumper' => ['Dumper'],
#     POSIX => [],
# }
#
# The name is a bit of a misnomer. It starts out as a list of original imports,
# but with each include that gets processed, this list also gets updated. We do
# this so that we can keep track of what previous modules are really importing.
# Might not be bad to rename this.

sub _build_original_imports {
    my $self = shift;

    # We're missing requires which could be followed by an import.
    my $found = $self->ppi_document->find(
        sub {
            $_[1]->isa('PPI::Statement::Include')
                && !$_[1]->pragma     # no pragmas
                && !$_[1]->version    # Perl version requirement
                && $_[1]->type
                && $_[1]->type eq 'use';
        }
    ) || [];

    my %imports;

    for my $include ( @{$found} ) {
        my $pkg = $include->module;
        $imports{$pkg} = undef unless exists $imports{$pkg};

        # this is probably wrong
        #next if $self->_is_ignored($pkg);

        # If a module has been included multiple times, we want to have a
        # cumulative tally of what has been explicitly imported.
        my $found = $self->_imports_for_include($include);
        if ($found) {
            if ( $imports{$pkg} ) {
                push @{ $imports{$pkg} }, @{$found};
            }
            else {
                $imports{$pkg} = $found;
            }
        }
    }

    return \%imports;
}

sub _build_sub_exporter_export_list {
    my $self = shift;

    my $sub_ex = $self->ppi_document->find(
        sub {
            $_[1]->isa('PPI::Statement::Include')
                && $_[1]->module eq 'Sub::Exporter';
        }
    ) || [];
    return [] unless @{$sub_ex};

    my @found;
    for my $include ( @{$sub_ex} ) {
        my @arguments = $include->arguments;
        for my $arg (@arguments) {
            if ( $arg->isa('PPI::Structure::Constructor') ) {
                ## no critic (BuiltinFunctions::ProhibitStringyEval)
                my $thing = eval $arg;
                if ( is_plain_hashref($thing) ) {
                    if ( is_plain_arrayref( $thing->{exports} ) ) {
                        push @found, @{ $thing->{exports} };
                    }
                }
            }
        }
    }

    return [ uniq @found ];
}

sub _imports_for_include {
    my $self    = shift;
    my $include = shift;

    my $imports = undef;

    for my $child ( $include->schildren ) {
        if ( $child->isa('PPI::Structure::List')
            && !defined $imports ) {
            $imports = [];
        }
        if (   !$child->isa('PPI::Token::QuoteLike::Words')
            && !$child->isa('PPI::Token::Quote::Single') ) {
            next;
        }
        my @imports = $child->literal;
        if ( defined $imports ) {
            push( @{$imports}, $child->literal );
        }
        else {
            $imports = [ $child->literal ];
        }
    }
    return $imports;
}

sub _extract_symbols_from_snippet {
    my $self    = shift;
    my $snippet = shift;
    return () unless defined $snippet;

    # Restore line breaks and tabs
    $snippet =~ s{\\n}{\n}g;
    $snippet =~ s{\\t}{\t}g;

    my $doc = PPI::Document->new( \$snippet );
    my @symbols
        = map { $_ . q{} } @{ $doc->find('PPI::Token::Symbol') || [] };

    my $casts = $doc->find('PPI::Token::Cast') || [];
    for my $cast ( @{$casts} ) {

        # Optimistically avoid misinterpreting regex assertions as casts
        # We don't want to match on "A" in the following example:
        # if ( $thing =~ m{ \A b }x ) { ... }
        next if $cast eq '\\';

        my $full_cast   = $cast . $cast->snext_sibling;
        my $cast_as_doc = PPI::Document->new( \$full_cast );
        push @symbols,
            map { $_ . q{} }
            @{ $cast_as_doc->find('PPI::Token::Symbol') || [] };

        my $words = $cast_as_doc->find('PPI::Token::Word') || [];

        ## Turn ${FOO} into $FOO
        if (   $words
            && scalar @$words == 1
            && $full_cast =~ m/([\$\@\%])\{$words->[0]}/ ) {
            push @symbols, $1 . $words->[0];
            next;
        }

        # This could likely be a source of false positives.
        for my $word (@$words) {
            push @symbols, "$word" if is_function_call($word);
        }
    }

    return @symbols;
}

sub _unnest_quotes {
    my $self  = shift;
    my $token = shift;
    my @words = @_;

    if (  !$token->isa('PPI::Token::Quote')
        || $token->isa('PPI::Token::Quote::Single') ) {
        return @words;
    }

    push @words, $self->_extract_symbols_from_snippet( $token->string );

    my $doc    = PPI::Document->new( \$token->string );
    my $quotes = $doc->find('PPI::Token::Quote');
    return @words unless $quotes;

    for my $q (@$quotes) {
        push @words, $self->_extract_symbols_from_snippet("$q");
        push @words, $self->_unnest_quotes($q);
    }

    return @words;
}

sub _build_interpolated_symbols {
    my $self = shift;
    my @symbols;

    for my $token (
        @{
            $self->ppi_document->find(
                sub {
                    ( $_[1]->isa('PPI::Token::Quote')
                            && !$_[1]->isa('PPI::Token::Quote::Single') )
                        || $_[1]->isa('PPI::Token::Quote::Interpolate')
                        || $_[1]->isa('PPI::Token::QuoteLike::Regexp')
                        || $_[1]->isa('PPI::Token::Regexp');
                }
                )
                || []
        }
    ) {
        if (   $token->isa('PPI::Token::Regexp')
            || $token->isa('PPI::Token::QuoteLike::Regexp') ) {
            for my $snippet (
                $token->get_match_string,
                $token->get_substitute_string,
            ) {
                push @symbols, $self->_extract_symbols_from_snippet($snippet);
            }
        }

        push @symbols, $self->_unnest_quotes($token);
    }

    # Crude hack to catch vars like ${FOO_BAR} in heredocs.
    for my $heredoc (
        @{
            $self->ppi_document->find(
                sub {
                    $_[1]->isa('PPI::Token::HereDoc');
                }
                )
                || []
        }
    ) {
        my $content = join "\n", $heredoc->heredoc;
        next if $heredoc =~ m{'};
        push @symbols, $self->_extract_symbols_from_snippet($content);
    }

    # Catch vars like ${FOO_BAR}. This is probably not good enough.
    for my $cast (
        @{
            $self->ppi_document->find(
                sub { $_[1]->isa('PPI::Token::Cast'); }
                )
                || []
        }
    ) {
        if (   !$cast->snext_sibling
            || !$cast->snext_sibling->isa('PPI::Structure::Block') ) {
            next;
        }

        my $sigil   = $cast . q{};
        my $sibling = $cast->snext_sibling . q{};
        if ( $sibling =~ m/{(\w+)}/ ) {
            push @symbols, $sigil . $1;
        }
    }
    my %symbols = map { $_ => 1 } @symbols;
    return \%symbols;
}

# Returns a HashRef of modules which will always be converted to avoid imports.
# This is mostly for speed and a matter of convenience so that we don't have to
# examine modules (like strictly Object Oriented modules) which we know will
# not have anything to export.

sub _build_never_exports {
    my $self = shift;

    my %modules = (
        'App::perlimports::Include' => 1,
        'File::Spec'                => 1,
        'HTTP::Daemon'              => 1,
        'HTTP::Headers'             => 1,
        'HTTP::Response'            => 1,
        'HTTP::Tiny'                => 1,
        'LWP::UserAgent'            => 1,
        'URI'                       => 1,
        'WWW::Mechanize'            => 1,
    );

    if ( $self->_has_never_export_modules ) {
        for my $module ( @{ $self->_never_export_modules } ) {
            $modules{$module} = 1;
        }
    }

    return \%modules;
}

sub _build_sub_names {
    my $self = shift;

    my %sub_names;
    for my $sub (
        @{
            $self->ppi_document->find(
                sub { $_[1]->isa('PPI::Statement::Sub') }
                )
                || []
        }
    ) {
        my @children = $sub->schildren;
        if (   $children[0] eq 'sub'
            && $children[1]->isa('PPI::Token::Word') ) {
            $sub_names{"$children[1]"} = 1;
        }
    }

    return \%sub_names;
}

sub _has_import_switches {
    my $self        = shift;
    my $module_name = shift;

    # If switches are being passed to import, we can't guess as what is correct
    # here.
    #
    # Getopt::Long uses a leading colon rather than a dash. This overrides
    # Exporter's defaults. You would normally assume that :config is an export
    # tag, but instead it's something entirely different.
    #
    # use Getopt::Long qw(:config no_ignore_case bundling);
    #
    # We will leave this case as broken for the time being. I'm not sure how
    # common that invocation is.

    if (
        exists $self->original_imports->{$module_name}
        && any { $_ =~ m{^[\-]} }
        @{ $self->original_imports->{$module_name} || [] }
    ) {
        return 1;
    }
    return 0;
}

sub _is_used_fully_qualified {
    my $self        = shift;
    my $module_name = shift;

    # We could tighten this up and check that the word following "::" is a sub
    # which exists in that package.
    #
    # Module::function
    # Module::->new
    # isa => ArrayRef[Module::]
    return 1 if $self->ppi_document->find(
        sub {
            (
                $_[1]->isa('PPI::Token::Word')
                    && (
                    $_[1]->content =~ m{\A${module_name}::[a-zA-Z0-9_]*\z}
                    || (   $_[1]->content eq ${module_name}
                        && $_[1]->snext_sibling eq '->' )
                    )
                )
                || ( $_[1]->isa('PPI::Token::Symbol')
                && $_[1] =~ m{\A[*\$\@\%]+${module_name}::[a-zA-Z0-9_]} );
        }
    );

    # We could combine the regexes, but this is easy to read.
    for my $key ( keys %{ $self->interpolated_symbols } ) {

        # package level variable
        return 1 if $key =~ m{\A[*\$\@\%]+${module_name}::[a-zA-Z0-9_]+\z};

        # function
        return 1 if $key =~ m/\A${module_name}::[a-zA-Z0-9_]+\z/;
    }

    return 0;
}

sub _is_ignored {
    my $self    = shift;
    my $element = shift;

    my $res
        = exists $default_ignore{ $element->module }
        || exists $self->_ignore_modules->{ $element->module }
        || $self->_annotations->is_ignored($element)
        || (
        any { $element->module =~ /$_/ }
        grep { $_ } @{ $self->_ignore_modules_pattern || [] }
        )
        || ( $self->inspector_for( $element->module )
        && !$self->inspector_for( $element->module )->evals_ok );
    return $res;
}

sub inspector_for {
    my $self   = shift;
    my $module = shift;

    # This would produce a warning and no helpful information.
    return undef if $module eq 'Exporter';

    if ( $self->_has_inspector_for($module) ) {
        return $self->_get_inspector_for($module);
    }

    if ( $self->_cache ) {
        require Sereal::Decoder;    ## no perlimports
        my $decoder = Sereal::Decoder->new( {} );
        my $file    = $self->_cache_file_for_module($module);
        my $inspector;
        if ( -e $file ) {
            try {
                $inspector = $decoder->decode_from_file($file);
                $self->_set_inspector_for( $module, $inspector );
            }
            catch {
                $self->logger->error($_);
            };
            if ($inspector) {
                $self->logger->info("Using cached version of $module");
                $inspector->set_logger( $self->logger );
                return $inspector;
            }
        }
    }

    try {
        $self->_set_inspector_for(
            $module,
            App::perlimports::ExportInspector->new(
                logger      => $self->logger,
                module_name => $module,
            )
        );
    }
    catch {
        $self->logger->info( 'inspector_for' . $_ );
        $self->_set_inspector_for( $module, undef );
    };

    return $self->_get_inspector_for($module);
}

sub _build_tidied_document {
    my $self = shift;

    my %processed;

    foreach my $include ( $self->all_includes ) {

        # If a module is used more than once, that's usually a mistake.
        if ( !$self->_preserve_duplicates
            && exists $processed{ $include->module } ) {
            $self->logger->info( $include->module
                    . ' has already been used. Removing at line '
                    . $include->line_number );
            $self->_remove_with_trailing_characters($include);
            next;
        }

        $self->logger->notice( '📦 ' . "Processing include: $include" );

        my $e = App::perlimports::Include->new(
            document         => $self,
            include          => $include,
            logger           => $self->logger,
            original_imports => $self->original_imports->{ $include->module },
            pad_imports      => $self->_padding,
            tidy_whitespace  => $self->_tidy_whitespace,
        );
        my $elem;
        try {
            $elem = $e->formatted_ppi_statement;
        }
        catch {
            my $error = $_;
            $self->logger->error( 'Error in ' . $self->_filename );
            $self->logger->error( 'Trying to format: ' . $include );
            $self->logger->error( 'Error is: ' . $error );
        };

        next unless $elem;

        # If this is a module with bare imports which is not used anywhere,
        # maybe we can just remove it.
        if ( !$self->_preserve_unused ) {
            my @args = $elem->arguments;

            if (   $args[0]
                && $args[0] eq '()'
                && !$self->_is_used_fully_qualified( $include->module ) ) {
                $self->logger->info( 'Removing '
                        . $include->module
                        . ' as it appears to be unused' );
                $self->_remove_with_trailing_characters($include);
                next;
            }
        }

        # Let's see if the import itself might break something
        if ( my $err
            = App::perlimports::Sandbox::eval_pkg( $elem->module, "$elem" ) )
        {
            $self->logger->warning(
                sprintf(
                    'New include (%s) triggers error (%s)', $elem, $err
                )
            );
            next;
        }

        # https://github.com/Perl-Critic/PPI/issues/189
        my $inserted = $include->insert_before($elem);
        if ( !$inserted ) {
            $self->logger->error( 'Could not insert ' . $elem );
        }
        else {
            $include->remove;
            $processed{ $include->module } = 1;

            $self->logger->info("resetting imports for |$elem|");

            # Now reset original_imports so that we can account for any changes
            # when processing includes further down the list.
            my $doc = PPI::Document->new( \"$elem" );

            if ( !$doc ) {
                $self->logger->error("PPI could not parse $elem");
            }
            else {
                my $new_include
                    = $doc->find(
                    sub { $_[1]->isa('PPI::Statement::Include') } );

                $self->_reset_original_import(
                    $include->module,
                    $self->_imports_for_include( $new_include->[0] )
                );
            }
        }
    }

    $self->_maybe_cache_inspectors;

    # We need to do this in order to preserve HEREDOCs.
    # See https://metacpan.org/pod/PPI::Document#serialize
    return $self->_ppi_selection->serialize;
}

sub _remove_with_trailing_characters {
    my $self    = shift;
    my $include = shift;

    while ( my $next = $include->next_sibling ) {
        if (   !$next->isa('PPI::Token::Whitespace')
            && !$next->isa('PPI::Token::Comment') ) {
            last;
        }
        $next->remove;
        last if $next eq "\n";
    }
    $include->remove;
    return;
}

sub _build_cache_dir {
    my $self = shift;

    my $cache_dir;
    my $base_path
        = defined $ENV{HOME} && -d path( $ENV{HOME}, '.cache' )
        ? path( $ENV{HOME}, '.cache' )
        : path('/tmp');

    $cache_dir = $base_path->child( 'perlimports', $VERSION );
    $cache_dir->mkpath;

    return $cache_dir;
}

sub _cache_file_for_module {
    my $self   = shift;
    my $module = shift;

    return $self->_cache_dir->child($module);
}

sub _maybe_cache_inspectors {
    my $self = shift;
    return unless $self->_cache;

    my @names = sort $self->all_inspector_names;
    $self->logger->info("maybe cache");
    return unless @names;

    my $append = 0;
    require Sereal::Encoder;    ## no perlimports
    my $encoder = Sereal::Encoder->new(
        { croak_on_bless => 0, undef_unknown => 1, } );

    for my $name ( $self->all_inspector_names ) {
        my $file = $self->_cache_file_for_module($name);
        next if -e $file;

        $self->logger->info("I would like to cache $name at $file");
        $encoder->encode_to_file(
            $file,
            $self->inspector_for($name),
            $append
        );
    }
    return;
}

1;

# ABSTRACT: Make implicit imports explicit

=pod

=head2 inspector_for( $module_name )

Returns an L<App::perlimports::ExporterInspector> object for the given module.

=head2 tidied_document

Returns a serialized PPI document with (hopefully) tidy import statements.

=cut
