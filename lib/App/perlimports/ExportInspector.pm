package App::perlimports::ExportInspector;

use Moo;

our $VERSION = '0.000001';

use App::perlimports::Importer::Exporter    ();
use App::perlimports::Importer::SubExporter ();
use Class::Inspector                        ();
use Data::Printer;
use List::Util qw( any );
use Module::Runtime qw( require_module );
use PPI::Document ();
use Sub::HandlesVia;
use Try::Tiny qw( catch try );
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Maybe Str);

has combined_exports => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        has_combined_exports => 'count',
    },
    lazy    => 1,
    default => sub { $_[0]->inspection->all_exports },
);

has default_exports => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        has_default_exports => 'count',
    },
    lazy    => 1,
    default => sub { $_[0]->inspection->default_exports },
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

has export => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        default_export_names => 'keys',
    },
    lazy    => 1,
    default => sub { $_[0]->inspection->default_exports },
);

has export_fail => (
    is          => 'ro',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        has_export_fail => 'count',
    },
    lazy    => 1,
    default => sub { $_[0]->inspection->export_fail },
);

has export_ok => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        _has_export_ok => 'keys',
    },
    lazy    => 1,
    default => sub { $_[0]->inspection->export_ok },
);

has export_tags => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        export_tag_names => 'keys',
    },
    lazy    => 1,
    default => sub { $_[0]->inspection->export_tags },
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
    is      => 'ro',
    isa     => InstanceOf ['App::perlimports::ExportInspector::Inspection'],
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
    );

    if ( $exporter->has_errors ) {
        $self->_add_error for @{ $exporter->errors };
    }

    return $exporter if $exporter->is_exporter;

    my $sub_exporter
        = App::perlimports::Importer::SubExporter::maybe_get_exports(
        $self->_module_name );

    if ( $sub_exporter->has_errors ) {
        $self->_add_error for @{ $sub_exporter->errors };
    }
    return $sub_exporter if $sub_exporter->is_sub_exporter;

    # If it's neither, return the $exporter, because it will probably have a
    # more useful class_isa.
    return $exporter;
}

sub _build_is_oo_class {
    my $self = shift;

    my $methods
        = Class::Inspector->methods( $self->_module_name, 'full', 'public' );

    return any {
        $_ eq 'Moose::Object::BUILDALL' || $_ eq 'Moo::Object::BUILDALL'
    }
    @{$methods};
}

sub module_is_exporter {
    my $self = shift;
    return $self->inspection->is_exporter;
}

sub class_isa {
    return shift->inspection->class_isa;
}

sub is_moose_class {
    return shift->inspection->is_moose_class;
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
