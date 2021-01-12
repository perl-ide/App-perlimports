package App::perlimports::ExportInspector;

use Moo;

use App::perlimports::Importer::Exporter    ();
use App::perlimports::Importer::SubExporter ();
use Data::Printer;
use List::Util qw( any );
use Module::Runtime qw( module_notional_filename require_module );
use MooX::HandlesVia;
use Path::Tiny qw( path );
use Try::Tiny qw( catch try );
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

has _export_lists => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_export_lists',
);

has export => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub { $_[0]->_export_lists->{export} || [] },
);

has export_ok => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub { $_[0]->_export_lists->{export_ok} || [] },
);

has is_moose_type_library => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_has_moose_types && defined $self->_moose_types;
    },
);

has _module_name => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'module_name',
    required => 1,
);

# If this attribute is undef, it means we tried to look for Moose types but
# this probably is not a Moose type library.
has _moose_types => (
    is        => 'ro',
    isa       => Maybe [ArrayRef],
    predicate => '_has_moose_types',
    lazy      => 1,
    builder   => '_build_moose_types',
);

has _uses_sub_exporter => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_uses_sub_exporter',
);

sub _build_combined_exports {
    my $self = shift;

    my %exports
        = map { $_ => $_ } ( @{ $self->export }, @{ $self->export_ok } );

    if ( !keys %exports && $self->_uses_sub_exporter ) {
        my ( $export, $error )
            = App::perlimports::Importer::SubExporter::maybe_get_all_exports(
            $self->_module_name );
        $self->_add_error($error) if $error;
        %exports = %{$export};
    }

    if ( !keys %exports && $self->_moose_types ) {
        %exports = map { $_ => $_ } @{ $self->_moose_types };
    }

    # If we have undef for Moose types, we don't want to return that in this
    # builder, since this attribute cannot be undef.
    return keys %exports ? \%exports : {};
}

sub _build_export_lists {
    my $self = shift;
    my ( $export, $export_ok, $error )
        = App::perlimports::Importer::Exporter::maybe_require_and_import_module(
        $self->_module_name );
    $self->_add_error($error) if $error;

    return {
        export    => $export,
        export_ok => $export_ok,
    };
}

# Moose Type library? And yes, private method bad.
sub _build_moose_types {
    my $self = shift;

    my @exports;

    # Don't wrap this require as we really do want to die if Class::Inspector
    # cannot be found.
    require_module('Class::Inspector');

    if (
        any { $_ eq 'MooseX::Types::Combine::_provided_types' }
        @{ Class::Inspector->methods(
                $self->_module_name, 'full', 'private'
                )
                || []
        }
    ) {
        my %types = $self->_module_name->_provided_types;
        @exports = map { $_, 'is_' . $_, 'to_' . $_ } keys %types;
    }
    return @exports ? \@exports : undef;
}

sub _build_uses_sub_exporter {
    my $self = shift;

    my $filename = module_notional_filename( $self->_module_name );
    if ( !exists $INC{$filename} ) {
        $self->_add_error(
            sprintf(
                'Cannot find %s when testing for Sub::Exporter',
                $self->_module_name
            )
        );
        return;
    }

    my $content = path( $INC{$filename} )->slurp;
    my $doc     = PPI::Document->new( \$content );

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnfoundImport
    my $include_statements = $doc->find(
        sub {
            $_[1]->isa('PPI::Statement::Include') && !$_[1]->pragma;
        }
    ) || [];
    for my $st (@$include_statements) {
        next if $st->schild(0) eq 'no';

        my $included_module = $st->schild(1);
        if ( $included_module eq 'Sub::Exporter' ) {
            return 1;
        }
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

=head2 is_moose_type_library

Returns a Boolean to indicate whether we know this to be a L<Moose> type
library.

=head1 CAVEATS

This will not work with modules using L<Sub::Exporter> or code which uses some
other creative way of managing symbol exports.

=cut
