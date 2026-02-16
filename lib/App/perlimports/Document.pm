package App::perlimports::Document;

use Moo;
use utf8;

our $VERSION = '0.000059';

use App::perlimports::Annotations     ();
use App::perlimports::ExportInspector ();
use App::perlimports::Include         ();
use App::perlimports::Sandbox         ();
use File::Basename                    qw( fileparse );
use List::Util                        qw( any uniq );
use Module::Runtime                   qw( module_notional_filename );
use MooX::StrictConstructor;
use Path::Tiny                  qw( path );
use PPI::Document               ();
use PPIx::Utils::Classification qw(
    is_function_call
    is_hash_key
    is_method_call
);
use Ref::Util    qw( is_plain_arrayref is_plain_hashref );
use Scalar::Util qw( refaddr );
use Sub::HandlesVia;
use Text::Diff      ();
use Try::Tiny       qw( catch try );
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

# list of PPI::Statement::Include (use, no, require)
# (excluding pragmas, ignored modules, and 'use VERSION')
has includes => (
    is          => 'ro',
    isa         => ArrayRef [Object],    # PPI::Statement::Include
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

# catalog of variables seen in interpolated context (string, qr, et al)
has interpolated_symbols => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_interpolated_symbols',
);

# (lint mode only) whether to output json (or else console text)
has json => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 0,
);

has _json_encoder => (
    is      => 'ro',
    isa     => InstanceOf ['Cpanel::JSON::XS'],
    lazy    => 1,
    default => sub {
        require Cpanel::JSON::XS;
        return Cpanel::JSON::XS->new;
    },
);

# are we processing in lint mode ? (otherwise edit mode)
has lint => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 0,
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

# catalog of symbols explicitly imported (by package), e.g.
#  Carp => ['croak', ..], ...
# in edit mode, this will be altered after processing (tidied_document)
# to reflect what we think the import statement should be.
has found_imports => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        _reset_found_import => 'set',
    },
    lazy    => 1,
    builder => '_build_found_imports',
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

# list of tokens in the document that -could- have come from an import
# (but most are keywords, built-ins, lexical vars, defined funcs, etc.)
has possible_imports => (
    is      => 'ro',
    isa     => ArrayRef [Object],        # isa PPI:Token:Word, :Symbol, :Magic
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

# catalog of the named subs defined, e.g.
#   new => 1, ...
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
    'Class::XSAccessor'              => 1,
    'Constant::Generate'             => 1,
    'Data::Printer'                  => 1,
    'DDP'                            => 1,
    'Devel::Confess'                 => 1,
    'DynaLoader'                     => 1,
    'Encode::Guess'                  => 1,
    'Env'                            => 1,    # see t/env.t
    'Exception::Class'               => 1,
    'Exporter'                       => 1,
    'Exporter::Lite'                 => 1,
    'Feature::Compat::Try'           => 1,
    'Filter::Simple'                 => 1,
    'Git::Sub'                       => 1,
    'HTTP::Message::PSGI'            => 1,    # HTTP::Request::(to|from)_psgi
    'Import::Into'                   => 1,
    'MLDBM'                          => 1,
    'Modern::Perl'                   => 1,
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
    'namespace::clean'                                    => 1,
    'PerlIO::gzip'                                        => 1,
    'Regexp::Common'                                      => 1,
    'Sort::ByExample'                                     => 1,
    'Struct::Dumb'                                        => 1,
    'Sub::Exporter'                                       => 1,
    'Sub::Exporter::Progressive'                          => 1,
    'Sub::HandlesVia'                                     => 1,
    'Syntax::Keyword::Try'                                => 1,
    'Term::Size::Any'                                     => 1,
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

    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    return $self->_ppi_selection->find(
        sub {
            $_[1]->isa('PPI::Statement::Include')
                && !$_[1]->pragma     # no pragmas
                && !$_[1]->version    # Perl version requirement
                && $_[1]->type
                && ( $_[1]->type eq 'use'
                || $_[1]->type eq 'require' )
                && !$self->_is_ignored( $_[1] )
                && !$self->_has_import_switches( $_[1]->module )
                && !App::perlimports::Sandbox::eval_pkg(
                $_[1]->module,
                "$_[1]"
                );
        }
    ) || [];
    ## use critic
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

        next if !$word->isa('PPI::Token::Symbol') && is_method_call($word);

        next if $self->_is_word_interpreted_as_string($word);

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
# In lint mode, it never changes.  In edit mode, it starts out as a list of
# original imports, but with each include that gets processed, this list gets
# updated. We do this so that we can keep track of what previous modules
# are really importing, avoiding duplicate imports.

sub _build_found_imports {
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
        my $found_for_include = _imports_for_include($include);
        if ($found_for_include) {
            if ( $imports{$pkg} ) {
                my %catalog = map { $_ => 1 } @{ $imports{$pkg} },
                    @{$found_for_include};
                $imports{$pkg} = [ sort keys %catalog ];
            }
            else {
                $imports{$pkg} = $found_for_include;
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
    my $snippet = shift;
    return () unless defined $snippet;

    # Restore line breaks and tabs
    $snippet =~ s{\\n}{\n}g;
    $snippet =~ s{\\t}{\t}g;

    my $doc = PPI::Document->new( \$snippet );
    return () unless defined $doc;

    my @symbols
        = map { $_ . q{} } @{ $doc->find('PPI::Token::Symbol') || [] };

    my $casts = $doc->find('PPI::Token::Cast') || [];
    for my $cast ( @{$casts} ) {

        # PPI Edge Case: False positive casts from regex assertions
        #
        # PPI can misinterpret regex assertions like \A as casts. We don't
        # want to match on "A" in: if ( $thing =~ m{ \A b }x ) { ... }
        #
        # See also: Similar PPI edge case for quote operators at line ~596
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

    push @words, _extract_symbols_from_snippet( $token->string );

    my $doc = PPI::Document->new( \$token->string );
    return @words unless $doc;

    my $quotes = $doc->find('PPI::Token::Quote');
    return @words unless $quotes;

    for my $q (@$quotes) {

        # PPI Edge Case: False positive quote operators
        #
        # PPI sometimes misinterprets content inside double-quoted strings as
        # quote operators. For example, when parsing pack("qq", ...), PPI may
        # identify the bare "qq" as a PPI::Token::Quote even though it's just
        # a string literal. Calling ->string on these false positives causes
        # "Use of uninitialized value" errors because they lack actual content.
        #
        # Detection: Real quote operators have delimiters (e.g., q{}, qq[],
        # qw()). False positives are just the bare operator name.
        #
        # See also: Similar PPI edge case handling for casts at line ~546
        # where regex assertions like \A can be misinterpreted as casts.
        my $quote_str = "$q";
        next if $quote_str =~ m/\A(?:qq?|qw|qx|qr|m|s|tr|y)\z/;

        push @words, _extract_symbols_from_snippet("$q");
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
                push @symbols, _extract_symbols_from_snippet($snippet);
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
        push @symbols, _extract_symbols_from_snippet($content);
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

    if ( exists $self->found_imports->{$module_name}
        && any { $_ =~ m{^[\-]} }
        @{ $self->found_imports->{$module_name} || [] } ) {
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
                && $_[1] =~ m{\A[&*\$\@\%]+${module_name}::[a-zA-Z0-9_]} );
        }
    );

    # We could combine the regexes, but this is easy to read.
    for my $key ( keys %{ $self->interpolated_symbols } ) {

        # package level variable
        return 1 if $key =~ m{\A[&*\$\@\%]+${module_name}::[a-zA-Z0-9_]+\z};

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

# given a PPI:Statement:Include that exists in the doc,
# instantiate a App:perlimports:Include to process it.
sub _include_analyzer {
    my ( $self, $include ) = @_;

    return my $e = App::perlimports::Include->new(
        document        => $self,
        include         => $include,
        logger          => $self->logger,
        found_imports   => $self->found_imports->{ $include->module },
        pad_imports     => $self->_padding,
        tidy_whitespace => $self->_tidy_whitespace,
    );
}

sub tidied_document {
    return shift->_lint_or_tidy_document;
}

sub linter_success {
    return shift->_lint_or_tidy_document;
}

# Kind of on odd interface, but right now we return either a tidied document or
# the result of linting. Could probably clean this up at some point, but I'm
# not sure yet how much the linting will change.
# N.B. In lint mode, we never modify the document.
sub _lint_or_tidy_document {
    my $self = shift;

    my $linter_error = 0;
    my %processed;    # modules we changed/confirmed the use statement

INCLUDE:
    foreach my $include ( $self->all_includes ) {

        # If a module is used more than once, that's usually a mistake.
        if ( !$self->_preserve_duplicates
            && exists $processed{ $include->module } ) {

            if ( $self->lint ) {
                $self->_warn_diff_for_linter(
                    'has already been used and should be removed',
                    $include,
                    $include->content,
                    q{}
                );
                $linter_error = 1;
                next INCLUDE;
            }

            $self->logger->info( $include->module
                    . ' has already been used. Removing at line '
                    . $include->line_number );
            _remove_with_trailing_characters($include);
            next INCLUDE;
        }

        $self->logger->notice( '📦 ' . "Processing include: $include" );

        my $e = $self->_include_analyzer($include);
        my $elem;
        try {
            # may return the original include!
            $elem = $e->formatted_ppi_statement;
        }
        catch {
            my $error = $_;
            $self->logger->error( 'Error in ' . $self->_filename );
            $self->logger->error( 'Trying to format: ' . $include );
            $self->logger->error( 'Error is: ' . $error );
        };

        next INCLUDE unless $elem;

        # If this is a module with bare imports which is not used anywhere,
        # maybe we can just remove it.
        if ( !$self->_preserve_unused ) {
            my @args = $elem->arguments;

            if (   $args[0]
                && $args[0] eq '()'
                && !$self->_is_used_fully_qualified( $include->module ) ) {

                if ( $self->lint ) {
                    $self->_warn_diff_for_linter(
                        'appears to be unused and should be removed',
                        $include, $include->content,
                        q{}
                    );
                    $linter_error = 1;
                    next INCLUDE;
                }

                $self->logger->info( 'Removing '
                        . $include->module
                        . ' as it appears to be unused' );
                _remove_with_trailing_characters($include);

                next INCLUDE;
            }
        }

        # if the 'new' statement is actually just the original, skip!
        if ( $elem == $include ) {
            $processed{ $include->module } = 1;
            next INCLUDE;
        }

        ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
        # Let's see if the import itself might break something
        if ( my $err
            = App::perlimports::Sandbox::eval_pkg( $elem->module, "$elem" ) )
        {
            $self->logger->warning(
                sprintf(
                    'New include (%s) triggers error (%s)', $elem, $err
                )
            );
            next INCLUDE;
        }
        ## use critic

        my $inserted = $include->replace($elem);
        if ( !$inserted ) {
            $self->logger->error( 'Could not insert ' . $elem );
        }
        else {
            $processed{ $include->module } = 1;

            if ( $self->lint ) {
                my $before = join q{ },
                    map { $_->content } $include->arguments;
                my $after = join q{ }, map { $_->content } $elem->arguments;

                if ( $before ne $after ) {
                    $self->_warn_diff_for_linter(
                        'import arguments need tidying',
                        $include,
                        $include->content,
                        $elem->content
                    );
                    $linter_error = 1;
                }
                next INCLUDE;
            }

            $self->logger->info("resetting imports for |$elem|");

            $self->_reset_found_import(
                $include->module,
                _imports_for_include($elem)
            );
        }
    }

    $self->_maybe_cache_inspectors;

    # We need to do serialize in order to preserve HEREDOCs.
    # See https://metacpan.org/pod/PPI::Document#serialize
    return $self->lint ? !$linter_error : $self->_ppi_selection->serialize;
}

sub _warn_diff_for_linter {
    my $self          = shift;
    my $reason        = shift;
    my $include       = shift;
    my $before        = shift;
    my $after         = shift;
    my $after_deleted = !$after;

    my $json;
    my $justification;

    if ( $self->json ) {

        my $loc     = { start => { line => $include->line_number } };
        my $content = $include->content;
        my @lines   = split( m{\n}, $content );

        if ( $lines[0] =~ m{[^\s]} ) {
            $loc->{start}->{column} = @-;
        }
        $loc->{end}->{line}   = $include->line_number + @lines - 1;
        $loc->{end}->{column} = length( $lines[-1] );

        $json = {
            filename => $self->_filename,
            location => $loc,
            module   => $include->module,
            reason   => $reason,
        };
    }
    else {
        $justification = sprintf(
            '❌ %s (%s) at %s line %i',
            $include->module, $reason, $self->_filename, $include->line_number
        );
    }

    my $padding = $include->line_number - 1;
    $before = sprintf( "%s%s\n", "\n" x $padding, $before );
    $after  = sprintf( "%s%s\n", "\n" x $padding, $after );
    chomp $after if $after_deleted;

    my $diff = Text::Diff::diff(
        \$before, \$after,
        {
            CONTEXT => 0,
            STYLE   => 'Unified',
        }
    );

    if ( $self->json ) {
        $json->{diff} = $diff;
        $self->logger->error( $self->_json_encoder->encode($json) );
    }
    else {
        $self->logger->error($justification);
        $self->logger->error($diff);
    }
}

sub _remove_with_trailing_characters {
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
    my $base_path
        = defined $ENV{HOME} && -d path( $ENV{HOME}, '.cache' )
        ? path( $ENV{HOME}, '.cache' )
        : path('/tmp');

    my $cache_dir = $base_path->child( 'perlimports', $VERSION );
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
    $self->logger->info('maybe cache');
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

sub _is_word_interpreted_as_string {
    my ( $self, $word ) = @_;

    return unless $word->statement && $word->isa('PPI::Token::Word');
    my @children = $word->statement->schildren;

    # https://perldoc.perl.org/perlref#Not-so-symbolic-references
    return 1 if is_hash_key($word) && @children == 1;

    # The => operator (sometimes pronounced "fat comma") is a synonym for
    # the comma except that it causes a word on its left to be interpreted
    # as a string if it begins with a letter or underscore and is composed
    # only of letters, digits and underscores. This includes operands that
    # might otherwise be interpreted as operators, constants, single number
    # v-strings or function calls.
    # https://perldoc.perl.org/perlop#Comma-Operator
    return unless $word->content =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/;

    while ( my $current = shift @children ) {
        last if refaddr($current) == refaddr($word);
    }
    return unless ( my $current = shift @children );
    return 1
        if $current->isa('PPI::Token::Operator')
        && $current->content eq '=>';
}

1;

# ABSTRACT: Make implicit imports explicit

=pod

=head1 MOTIVATION

This module is to be used internally by L<perlimports>. It shouldn't be relied
upon by anything else.

=head2 inspector_for( $module_name )

Returns an L<App::perlimports::ExporterInspector> object for the given module.

=head2 linter_success

Returns true if document was linted without errors, otherwise false.

=head2 tidied_document

Returns a serialized PPI document with (hopefully) tidy import statements.

=head1 ATTRIBUTES

=over 4

=item includes

An arrayref of L<PPI::Statement::Include> statements found in the document,
excluding pragmas, ignored modules, and 'use VERSION' statements.

=item found_imports

A hashref catalog of symbols imported from each package by a use statement,
e.g.

  { Carp => ['croak', ..], ... }

In lint mode, this attribute is never altered.

In edit mode, when L<tidied_document> is called, with each include that gets
processed, this list gets updated to what we think it should be.  We do this
so that we can keep track of what previous modules are really importing, to
avoid duplicate imports (same symbol name from different packages).

=back

=cut

