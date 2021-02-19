package App::perlimports::ExportInspector;

use Moo;

our $VERSION = '0.000001';

use App::perlimports::Importer::Exporter    ();
use App::perlimports::Importer::SubExporter ();
use Class::Inspector                        ();
use List::Util qw( any );
use Module::Runtime qw( require_module );
use PPI::Document ();
use Sub::HandlesVia;
use Types::Standard qw(ArrayRef Bool InstanceOf Str);

with 'App::perlimports::Role::Logger';

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

has import_flags => (
    is          => 'ro',
    isa         => ArrayRef,
    lazy        => 1,
    handles_via => 'Array',
    handles     => {
        has_import_flags => 'count',
    },
    builder => '_build_import_flags',
);

has inspection => (
    is  => 'ro',
    isa => InstanceOf ['App::perlimports::ExportInspector::Inspection'],
    handles_via => ['Object'],
    handles     => {
        class_isa            => 'class_isa',
        explicit_exports     => 'all_exports',
        default_exports      => 'default_exports',
        default_export_names => 'default_export_names',
        export_fail          => 'export_fail',
        export_tags          => 'export_tags',
        has_explicit_exports => 'has_all_exports',
        has_default_exports  => 'has_default_exports',
        has_export_fail      => 'has_export_fail',
        has_export_tags      => 'has_export_tags',
        is_moose_class       => 'is_moose_class',
        module_is_exporter   => 'is_exporter',
    },
    lazy    => 1,
    builder => '_build_inspection',
);

has is_oo_class => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_oo_class',
);

has _module_name => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'module_name',
    required => 1,
);

has warnings => (
    is          => 'rw',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        _add_warning => 'push',
        has_warnings => 'count',
    },
    init_arg => undef,
    default  => sub { [] },
);

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;

    my %args = @args;
    if ( $args{module_name} ) {
        require_module( $args{module_name} );
    }
    return $class->$orig(@args);
};

sub _build_import_flags {
    my $self = shift;

    my %modules = (
        Carp    => ['verbose'],
        English => ['-no_match_vars'],
    );

    return
        exists $modules{ $self->_module_name }
        ? $modules{ $self->_module_name }
        : [];
}

sub _build_inspection {
    my $self = shift;

    my $exporter = App::perlimports::Importer::Exporter::maybe_get_exports(
        $self->_module_name,
        $self->logger,
    );

    if ( $exporter->has_errors ) {
        $self->_add_error for @{ $exporter->errors };
    }

    return $exporter if $exporter->is_exporter;

    use DDP;
    p $self->logger;
    my $sub_exporter
        = App::perlimports::Importer::SubExporter::maybe_get_exports(
        $self->_module_name,
        $self->logger,
        );

    if ( $sub_exporter->has_errors ) {
        $self->_add_error for @{ $sub_exporter->errors };
    }
    if ( $sub_exporter->has_warnings ) {
        $self->_add_warning for @{ $sub_exporter->warnings };
    }

    # It may not actually be a Sub::Exporter, but if exports are found that
    # should generally be good enough.
    return $sub_exporter if $sub_exporter->has_all_exports;

    # If it's neither, return the $exporter, because it will probably have a
    # more useful class_isa.
    return $exporter;
}

sub _build_is_oo_class {
    my $self = shift;

    return 0 if $self->inspection->has_all_exports;

    my $methods
        = Class::Inspector->methods( $self->_module_name, 'full', 'public' );

    return any {
        $_ eq 'Moose::Object::BUILDALL' || $_ eq 'Moo::Object::BUILDALL'
    }
    @{$methods};
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

    my $exports = $ei->explicit_exports;

=head1 MOTIVATION

Since we're (maybe) importing symbols as part of this process, we've sandboxed
it a little bit by not doing it in L<App::perlimports> directly.

=head1 METHODS

The following methods are available.

=head2 errors

An ArrayRef of error messages which may have been triggered during inspection.

=head2 has_errors

Returns a Boolean to indicate whether any errors exist.

=head2 explicit_exports

HashRef which combines the unique contents of C<export> and C<export_ok>. If
this is a Moose type library, the exported types will exist in this list, but
not in C<export> or C<export_ok>.

=head1 CAVEATS

This may not work with modules using some creative way of managing symbol
exports.

=cut
