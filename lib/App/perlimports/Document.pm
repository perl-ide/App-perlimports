package App::perlimports::Document;

use Moo;

our $VERSION = '0.000001';

use App::perlimports ();
use Data::Printer;
use List::Util qw( any );
use MooX::StrictConstructor;
use Path::Tiny qw( path );
use PPI::Document 1.270 ();
use PPIx::QuoteLike               ();
use String::InterpolatedVariables ();
use Sub::HandlesVia;
use Try::Tiny qw( catch try );
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Maybe Object Str);

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
    is      => 'ro',
    isa     => HashRef,
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
    'namespace::autoclean'           => 1,
    'Regexp::Common'                 => 1,
    'Sub::Exporter'                  => 1,
    'Sub::HandlesVia'                => 1,
    'Test::Needs'                    => 1,
    'Test::RequiresInternet'         => 1,
    'Types::Standard'                => 1,
);

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

sub _build_original_imports {
    my $self = shift;

    my $found = $self->ppi_document->find(
        sub {
            $_[1]->isa('PPI::Statement::Include')
                && !$_[1]->pragma     # no pragmas
                && !$_[1]->version    # Perl version requirement
                && $_[1]->type
                && ( $_[1]->type eq 'use'
                || $_[1]->type eq 'require' );
        }
    ) || [];

    my %imports;

    for my $include ( @{$found} ) {
        my $pkg = $include->module;
        $imports{$pkg} = undef unless exists $imports{$pkg};

        for my $child ( $include->schildren ) {
            if ( $child->isa('PPI::Structure::List')
                && !$imports{$pkg} ) {
                $imports{$pkg} = [];
            }
            if (   !$child->isa('PPI::Token::QuoteLike::Words')
                && !$child->isa('PPI::Token::Quote::Single') ) {
                next;
            }
            my @imports = $child->literal;
            if ( exists $imports{$pkg} ) {
                push( @{ $imports{$pkg} }, $child->literal );
            }
            else {
                $imports{$pkg} = [ $child->literal ];
            }
        }
    }

    return \%imports;
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
        'App::perlimports' => 1,
        'HTTP::Daemon'     => 1,
        'HTTP::Headers'    => 1,
        'HTTP::Response'   => 1,
        'HTTP::Tiny'       => 1,
        'LWP::UserAgent'   => 1,
        'URI'              => 1,
        'WWW::Mechanize'   => 1,
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
    # Getopt::Long uses a leading colon rather than a dash.
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
                module_name => $module,
            )
        );
    }
    catch {
        warn $_;
        $self->_set_inspector_for( $module, undef );
    };

    return $self->_get_inspector_for($module);
}

sub tidied_document {
    my $self = shift;

    foreach my $include ( $self->all_includes ) {
        my $e = App::perlimports->new(
            document         => $self,
            include          => $include,
            original_imports => $self->original_imports->{ $include->module },
            pad_imports      => $self->_padding,
        );
        my $elem;
        try {
            $elem = $e->formatted_ppi_statement;
        }
        catch {
            print STDERR 'Error: ' . $self->_filename . "\n";
            print STDERR $include;
            print STDERR $_;
        };

        next unless $elem;

        # https://github.com/adamkennedy/PPI/issues/189
        my $inserted = $include->insert_before($elem);
        if ( !$inserted ) {
            print STDERR 'Could not insert ' . $elem;
        }
        else {
            $include->remove;
        }

        if ( $self->_verbose && $e->has_errors ) {
            print STDERR 'Error: ' . $self->_filename . "\n";
            print STDERR $e->_module_name . ' ' . np( $e->errors ) . "\n";
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
