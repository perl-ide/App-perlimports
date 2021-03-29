package App::perlimports::Document;

use Moo;
use utf8;

our $VERSION = '0.000001';

use App::perlimports::Include ();
use File::Basename qw( fileparse );
use List::Util qw( any uniq );
use Module::Runtime qw( module_notional_filename );
use MooX::StrictConstructor;
use Path::Tiny qw( path );
use PPI::Document 1.270 ();
use PPIx::QuoteLike               ();
use String::InterpolatedVariables ();
use Sub::HandlesVia;
use Try::Tiny qw( catch try );
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Maybe Object Str);

with 'App::perlimports::Role::Logger';

has _export_list => (
    is          => 'ro',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        all_document_exports => 'elements',
    },
    lazy    => 1,
    builder => '_build_export_list',
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

has interpolated_symbols => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_interpolated_symbols',
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
    'Data::Printer'                  => 1,
    'DDP'                            => 1,
    'Devel::Confess'                 => 1,
    'Exception::Class'               => 1,
    'Exporter'                       => 1,
    'Mojolicious::Lite'              => 1,
    'Moo'                            => 1,
    'Moo::Role'                      => 1,
    'Moose'                          => 1,
    'Moose::Exporter'                => 1,
    'MooseX::SemiAffordanceAccessor' => 1,
    'MooseX::StrictConstructor'      => 1,
    'MooseX::Types'                  => 1,
    'MooX::StrictConstructor'        => 1,
    'namespace::autoclean'           => 1,
    'Regexp::Common'                 => 1,
    'Sub::Exporter'                  => 1,
    'Sub::HandlesVia'                => 1,
    'Test2::Util::HashBase'          => 1,
    'Test::Exception'                => 1,
    'Test::Needs'                    => 1,
    'Test::Number::Delta'            => 1,
    'Test::Requires::Git'            => 1,
    'Test::RequiresInternet'         => 1,
    'Test::XML'                      => 1,
    'Types::Standard'                => 1,
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

sub _build_export_list {
    my $self = shift;
    my $i    = $self->my_own_inspector;

    return [
        uniq values %{ $i->all_exports },
        values %{ $i->default_exports }
    ];
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
                && !$self->_is_ignored( $_[1]->module )
                && !$self->_has_import_switches( $_[1]->module );
        }
    ) || [];
}

sub _build_ppi_document {
    my $self    = shift;
    my $content = path( $self->_filename )->slurp;
    return PPI::Document->new( \$content );
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

sub _build_interpolated_symbols {
    my $self = shift;
    my %symbols;

    for my $quote (
        @{
            $self->ppi_document->find(
                sub {
                    ( $_[1]->isa('PPI::Token::Quote')
                            && !$_[1]->isa('PPI::Token::Quote::Single') )
                        || $_[1]->isa('PPI::Token::QuoteLike::Regexp')
                        || $_[1]->isa('PPI::Token::Regexp');
                }
                )
                || []
        }
    ) {
        my $vars = String::InterpolatedVariables::extract($quote);
        for my $var ( @{$vars} ) {
            ++$symbols{$var};
        }

        # Match on @{[ ... ]}
        if ( $quote =~ m/ @ \{ \[ (.*) \] \} /x ) {
            my $doc   = PPI::Document->new( \$1 );
            my $words = $doc->find( sub { $_[1]->isa('PPI::Token::Word') } )
                || [];
            for my $word (@$words) {
                ++$symbols{$word};
            }
        }
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

        my $vars = String::InterpolatedVariables::extract($content);
        for my $var ( @{$vars} ) {
            if ( $var =~ m/([\$\@\%])\{(\w+)\}/ ) {
                $var = $1 . $2;
            }
            ++$symbols{$var};
        }
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
            ++$symbols{ $sigil . $1 };
        }
    }
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

    if (
        exists $self->original_imports->{$module_name}
        && any { $_ =~ m{^[\-:]} }
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
    return !!$self->ppi_document->find(
        sub {
            (
                $_[1]->isa('PPI::Token::Word')
                    && (
                    $_[1]->content =~ m{\A${module_name}::[a-zA-Z_]}
                    || (   $_[1]->content eq ${module_name}
                        && $_[1]->snext_sibling eq '->' )
                    )
                )
                || ( $_[1]->isa('PPI::Token::Symbol')
                && $_[1] =~ m{\A[*]+${module_name}::[a-zA-Z_]} );
        }
    );
}

sub _is_ignored {
    my $self   = shift;
    my $module = shift;

    return exists $default_ignore{$module}
        || exists $self->_ignore_modules->{$module};
}

sub inspector_for {
    my $self   = shift;
    my $module = shift;

    # This would produce a warning and no helpful information.
    return undef if $module eq 'Exporter';

    if ( $self->_has_inspector_for($module) ) {
        return $self->_get_inspector_for($module);
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

sub tidied_document {
    my $self = shift;

    my %processed;

    foreach my $include ( $self->all_includes ) {

        # If a module is used more than once, that's usually a mistake.
        if ( !$self->_preserve_duplicates
            && exists $processed{ $include->module } ) {
            $self->logger->info( $include->module
                    . ' has already been used. Removing at line '
                    . $include->line_number );
            if ( $include->next_sibling eq "\n" ) {
                $include->next_sibling->remove;
            }
            $include->remove;
            next;
        }

        $self->logger->notice( '📦 ' . "Processing include: $include" );

        my $e = App::perlimports::Include->new(
            document         => $self,
            include          => $include,
            logger           => $self->logger,
            original_imports => $self->original_imports->{ $include->module },
            pad_imports      => $self->_padding,
        );
        my $elem;
        try {
            $elem = $e->formatted_ppi_statement;
        }
        catch {
            $self->logger->error( $self->_filename );
            $self->logger->error($include);
            $self->logger->error($_);
        };

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
                if ( $include->next_sibling eq "\n" ) {
                    $include->next_sibling->remove;
                }
                $include->remove;
                next;
            }
        }

        next unless $elem;

        # https://github.com/adamkennedy/PPI/issues/189
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

    # We need to do this in order to preserve HEREDOCs.
    # See https://metacpan.org/pod/PPI::Document#serialize
    return $self->_ppi_selection->serialize;
}

1;

# ABSTRACT: Make implicit imports explicit

=pod

=head2 inspector_for( $module_name )

Returns an L<App::perlimports::ExporterInspector> object for the given module.

=head2 tidied_document

Returns a serialized PPI document with (hopefully) tidy import statements.

=cut
