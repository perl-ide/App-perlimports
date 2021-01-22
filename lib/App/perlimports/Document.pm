package App::perlimports::Document;

use Moo;

our $VERSION = '0.000001';

use MooX::HandlesVia qw( has );
use MooX::StrictConstructor;
use Path::Tiny qw( path );
use PPI::Document 1.270 ();
use PPIx::QuoteLike               ();
use String::InterpolatedVariables ();
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Maybe Object Str);

has _filename => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'filename',
    required => 1,
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

has original_imports => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_original_imports',
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
                || $_[1]->type eq 'require' );
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

1;

# ABSTRACT: Make implicit imports explicit

=pod
