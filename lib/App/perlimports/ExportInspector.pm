package App::perlimports::ExportInspector;

use Moo;

our $VERSION = '0.000001';

use App::perlimports::Importer::Exporter    ();
use App::perlimports::Importer::SubExporter ();
use Data::Printer;
use List::Util qw( any );
use MooX::HandlesVia;
use PPI::Document ();
use Types::Standard qw(ArrayRef Bool HashRef Maybe Str);

has combined_exports => (
    is      => 'ro',
    isa     => HashRef,
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
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    default => sub { $_[0]->_exporter_lists->{export} || [] },
);

has export_ok => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    default => sub { $_[0]->_exporter_lists->{export_ok} || [] },
);

has is_moose_class => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_moose_class',
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

sub _build_combined_exports {
    my $self = shift;

    my %exports = ( %{ $self->export }, %{ $self->export_ok } );

    if ( !keys %exports ) {
        %exports = %{ $self->_sub_exporter_inspection->{export} };
    }

    return \%exports;
}

sub _build_sub_exporter_inspection {
    my $self = shift;

    my ( $export, $attr, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_all_exports(
        $self->_module_name );
    $self->_add_error($error) if $error;
    return { export => $export, attr => $attr };
}

sub _build_exporter_lists {
    my $self = shift;
    my $lists
        = App::perlimports::Importer::Exporter::maybe_require_and_import_module(
        $self->_module_name );

    if ( my $error = delete $lists->{error} ) {
        $self->_add_error($error);
    }

    return $lists;
}

sub _build_is_moose_class {
    my $self = shift;

    $self->combined_exports;    # Ensure setup has been done
    my $class = $self->_module_name;

    if (   $class->can('meta')
        && $class->meta->can('superclasses')
        && any { $_ eq 'Moose::Object' } $class->meta->superclasses ) {
        return 1;
    }

    if (
        any { $_ eq 'Moose::Object' }
        @{ $self->_sub_exporter_inspection->{attr}->{isa} }
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
