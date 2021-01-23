package App::perlimports::Document;

use Moo;

our $VERSION = '0.000001';

use App::perlimports ();
use Data::Printer;
use List::Util qw( any );
use MooX::HandlesVia qw( has );
use MooX::StrictConstructor;
use Path::Tiny qw( path );
use PPI::Document 1.270 ();
use PPIx::QuoteLike               ();
use String::InterpolatedVariables ();
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

has vars => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_vars',
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

    return $class->$orig(%args);
};

my %default_ignore = (
    'Data::Printer'                  => 1,
    'Devel::Confess'                 => 1,
    'Exception::Class'               => 1,
    'Exporter'                       => 1,
    'Moo'                            => 1,
    'Moo::Role'                      => 1,
    'Moose'                          => 1,
    'Moose::Exporter'                => 1,
    'MooseX::SemiAffordanceAccessor' => 1,
    'MooseX::StrictConstructor'      => 1,
    'namespace::autoclean'           => 1,
    'Sub::Exporter'                  => 1,
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

    return $self->ppi_document->find(
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

sub _build_original_imports {
    my $self = shift;

    my $found
        = $self->ppi_document->find(
        sub { $_[1]->isa('PPI::Statement::Include'); } )
        || [];

    my %imports;
    for my $include ( @{$found} ) {
        for my $child ( $include->schildren ) {
            next unless $child->isa('PPI::Token::QuoteLike::Words');
            my @imports = $child->literal;
            if ( exists $imports{ $include->module } ) {
                push( @{ $imports{ $include->module } }, $child->literal );
            }
            else {
                $imports{ $include->module } = [ $child->literal ];
            }
        }
    }

    return \%imports;
}

sub _build_vars {
    my $self = shift;
    my %vars;

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
            ++$vars{$var};
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
            ++$vars{$var};
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
        next unless $cast->snext_sibling->isa('PPI::Structure::Block');

        my $sigil   = $cast . q{};
        my $sibling = $cast->snext_sibling . q{};
        if ( $sibling =~ m/{(\w+)}/ ) {
            ++$vars{ $sigil . $1 };
        }
    }
    return \%vars;
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

sub _has_import_switches {
    my $self        = shift;
    my $module_name = shift;

    # If switches are being passed to import, we can't guess as what is correct
    # here.
    if (
        exists $self->original_imports->{$module_name} && any { $_ =~ m{^\-} }
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

sub tidied_document {
    my $self = shift;

    foreach my $include ( $self->all_includes ) {
        my $imports = $self->original_imports->{ $include->module };

        my $e = App::perlimports->new(
            document => $self,
            include  => $include,
            $imports
            ? ( original_imports => $imports )
            : (),
            pad_imports => $self->_padding,
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
    return $self->ppi_document->serialize;
}

1;

# ABSTRACT: Make implicit imports explicit

=pod

=head2 tidied_document

Returns a serialized PPI document with (hopefully) tidy import statements.

=cut
