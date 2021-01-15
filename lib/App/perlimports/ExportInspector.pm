package App::perlimports::ExportInspector;

use Moo;

our $VERSION = '0.000001';

use App::perlimports::Importer::Exporter    ();
use App::perlimports::Importer::SubExporter ();
use Class::Inspector                        ();
use Data::Printer;
use List::Util qw( any );
use Module::Runtime qw( require_module );
use MooX::HandlesVia;
use PPI::Document ();
use Try::Tiny qw( catch try );
use Types::Standard qw(ArrayRef Bool HashRef Maybe Str);

has can_require_module => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_can_require_module',
);

has _class_isa => (
    is          => 'ro',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        class_isa => 'elements',
    },
    lazy    => 1,
    builder => '_build_class_isa',
);

has combined_exports => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        has_combined_exports => 'count',
    },
    lazy    => 1,
    builder => '_build_combined_exports',
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

has _exporter_lists => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_exporter_lists',
);

has export => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        _has_export => 'keys',
    },
    lazy    => 1,
    default => sub { $_[0]->_exporter_lists->{export} },
);

has export_ok => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        _has_export_ok => 'keys',
    },
    lazy    => 1,
    default => sub { $_[0]->_exporter_lists->{export_ok} },
);

has is_moose_class => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_moose_class',
);

has is_oo_class => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_oo_class',
);

has module_is_exporter => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_module_is_exporter',
);

has _module_name => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'module_name',
    required => 1,
);

has _sub_exporter_inspection => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_sub_exporter_inspection',
);

sub _build_can_require_module {
    my $self = shift;

    my $error;
    try {
        require_module( $self->_module_name );
    }
    catch {
        $error = $_;
    };

    return 1 if !$error;

    $self->_add_error($error) if $error;
    return 0;
}

sub _build_class_isa {
    my $self = shift;

    return [] unless $self->can_require_module;

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my $module = $self->_module_name;
    my @isa    = @{ $self->_module_name . '::ISA' };
    use strict;
    ## use critic

    return \@isa if @isa || $self->module_is_exporter;

    # For Moose, for example, we don't see anything in @ISA until the
    # Sub::Exporter inspection.
    return $self->_sub_exporter_inspection->{attr}->{isa} || [];
}

sub _build_combined_exports {
    my $self = shift;

    my %exports = ( %{ $self->export }, %{ $self->export_ok } );

    if ( !keys %exports ) {
        %exports = %{ $self->_sub_exporter_inspection->{export} };
    }

    return \%exports;
}

sub _build_module_is_exporter {
    my $self = shift;
    return (
        $self->can_require_module && ( $self->_has_export
            || $self->_has_export_ok )
    ) ? 1 : 0;
}

sub _build_sub_exporter_inspection {
    my $self = shift;

    # This is basically be a no-op if the module uses Exporter, but because we
    # try to import a tag which probably doesn't exist, this throws errors as
    # well, so let's make sure we bypass it entirely.
    if ( !$self->can_require_module || $self->module_is_exporter ) {
        return { export => {}, attr => {} };
    }

    my ( $export, $attr, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_exports(
        $self->_module_name );
    $self->_add_error($error) if $error;
    return { export => $export, attr => $attr };
}

sub _build_exporter_lists {
    my $self = shift;

    if ( !$self->can_require_module ) {
        return { export => {}, export_ok => {}, };
    }

    my $lists
        = App::perlimports::Importer::Exporter::maybe_get_exports(
        $self->_module_name );

    if ( my $error = delete $lists->{error} ) {
        $self->_add_error($error);
    }

    return $lists;
}

sub _build_is_oo_class {
    my $self = shift;
    return 0 unless $self->can_require_module;

    my $methods
        = Class::Inspector->methods( $self->_module_name, 'full', 'public' );

    return any {
        $_ eq 'Moose::Object::BUILDALL' || $_ eq 'Moo::Object::BUILDALL'
    }
    @{$methods};
}

sub _build_is_moose_class {
    my $self = shift;
    return 0 unless $self->can_require_module;

    my $class = $self->_module_name;

    if (
        (
            any { $_ eq 'Moose::Object' || $_ eq 'Test::Class::Moose' }
            $self->class_isa
        )
        && $self->has_combined_exports
    ) {
        return 1;
    }

    return 0;
}

1;

# ABSTRACT: Inspect code for exportable symbols

=pod

=head1 DESCRIPTION

Inspect modules to see what they might export.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use App::perlimport::ExportInspector ();

    my $ei = App::perlimport::ExportInspector->new(
        module_name => 'Carp',
    );

    my $exports = $ei->combined_exports;

=head1 MOTIVATION

Since we're (maybe) importing symbols as part of this process, we've sandboxed
it a little bit by not doing it in L<App::perlimports> directly.

=head1 METHODS

The following methods are available.

=head2 errors

An ArrayRef of error messages which may have been triggered during inspection.

=head2 has_errors

Returns a Boolean to indicate whether any errors exist.

=head2 export

ArrayRef of symbol names which roughly corresponds to C<@EXPORT>.

=head2 export_ok

ArrayRef of symbol names which roughly corresponds to C<@EXPORT_OK>.

=head2 combined_exports

ArrayRef which combines the unique contents of C<export> and C<export_ok>. If
this is a Moose type library, the exported types will exist in this list, but
not in C<export> or C<export_ok>.

=head1 CAVEATS

This may not work with modules using some creative way of managing symbol
exports.

=cut
