package App::perlimports::ExportInspector;

use Moo;

use Data::Printer;
use List::Util      ();
use Module::Runtime ();
use MooX::HandlesVia;
use Try::Tiny qw( catch try );
use Types::Standard qw(ArrayRef Bool Maybe Str);

has combined_exports => (
    is      => 'ro',
    isa     => ArrayRef,
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

has export => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_export',
);

has export_ok => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_export_ok',
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

# Abuse attributes to ensure this only happens once
has _maybe_require_and_import_module => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_maybe_require_and_import_module',
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

sub _build_maybe_require_and_import_module {
    my $self   = shift;
    my $module = $self->_module_name;

    my $error = 0;

    return 0 unless $self->_maybe_require_module($module);

    # This is helpful for (at least) POSIX and Test::Most
    try {
        $module->import;
    }
    catch {
        push @{ $self->errors }, $_;
    };

    return 1;
}

sub _build_combined_exports {
    my $self   = shift;
    my $module = $self->_module_name;

    my @exports
        = List::Util::uniq( @{ $self->export }, @{ $self->export_ok } );

    # If we have undef for Moose types, we don't want to return that in this
    # builder, since this attribute cannot be undef.
    return
          @exports            ? \@exports
        : $self->_moose_types ? $self->_moose_types
        :                       [];
}

sub _build_export {
    my $self = shift;

    $self->_maybe_require_and_import_module;

## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my @exports = @{ $self->_module_name . '::EXPORT' };
    use strict;
## use critic

    return @exports ? \@exports : [];
}

sub _build_export_ok {
    my $self = shift;

    $self->_maybe_require_and_import_module;

## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my @exports = @{ $self->_module_name . '::EXPORT_OK' };
    use strict;
## use critic

    return @exports ? \@exports : [];
}

# Moose Type library? And yes, private method bad.
sub _build_moose_types {
    my $self = shift;

    my @exports;

    # Don't wrap this require as we really do want to die if Class::Inspector
    # cannot be found.
    Module::Runtime::require_module('Class::Inspector');

    if (
        List::Util::any { $_ eq 'MooseX::Types::Combine::_provided_types' }
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

sub _maybe_require_module {
    my $self              = shift;
    my $module_to_require = shift;

    my $success;
    try {
        Module::Runtime::require_module($module_to_require);
        $success = 1;
    }
    catch {
        $self->_add_error("$module_to_require error. $_");
    };

    return $success;
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
