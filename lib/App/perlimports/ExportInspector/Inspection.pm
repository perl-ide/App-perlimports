package App::perlimports::ExportInspector::Inspection;

use Moo;

use List::Util qw( any );
use MooX::StrictConstructor;
use Sub::HandlesVia;
use Types::Standard qw( ArrayRef Bool HashRef Str );

has all_exports => (
    is          => 'ro',
    isa         => HashRef,
    init_arg    => 'explicit_exports',
    handles_via => 'Hash',
    handles     => {
        all_export_names  => 'keys',
        all_export_values => 'values',
        has_all_exports   => 'count',
    },
);

has class_isa => (
    is          => 'ro',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        has_class_isa => 'count',
    },
    default => sub { [] },
);

has default_exports => (
    is          => 'ro',
    isa         => HashRef,
    init_arg    => 'implicit_exports',
    default     => sub { +{} },
    handles_via => 'Hash',
    handles     => {
        default_export_names  => 'keys',
        default_export_values => 'values',
        has_default_exports   => 'count',
    },
);

has export_fail => (
    is          => 'ro',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        has_export_fail => 'count',
    },
    default => sub { [] },
);

has export_tags => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        has_export_tags => 'count',
    },
    default => sub { +{} },
);

has errors => (
    is          => 'ro',
    isa         => ArrayRef,
    handles_via => 'Array',
    handles     => {
        has_errors => 'count',
    },
    default => sub { [] },
);

has inspected_by => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has is_exporter => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

has is_sub_exporter => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

has is_moose_class => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_moose_class',
);

has _is_moose_type_class => (
    is  => 'ro',
    isa => Bool,
);

sub _build_is_moose_class {
    my $self = shift;

    if ( !$self->has_class_isa || !$self->has_all_exports ) {
        return 0;
    }

    return any { $_ eq 'Moose::Object' || $_ eq 'Test::Class::Moose' }
    @{ $self->class_isa };
}

sub all_imports_match_exports {
    my $self = shift;
    return
        join( q{}, sort $self->all_export_names ) eq
        join( q{}, sort $self->all_export_values );
}

sub default_imports_match_exports {
    my $self = shift;
    return
        join( q{}, sort $self->default_export_names ) eq
        join( q{}, sort $self->default_export_values );
}

1;

# ABSTRACT: Class to handle information about class exports

=pod

=head1 DESCRIPTION

This class has a few methods to describe what we think we know about what a
class exports.

=head1 METHODS

=head2 all_exports

C<HashRef> of all symbols which we think a class exports.

=head2 all_imports_match_exports

Returns true if import and export names match. Used to determine if we should
dump a one or two column table of import and export names.

=head2 class_isa

C<ArrayRef> of what we think the C<@ISA> for a class is. Note that C<@ISA> can
change when a class is imported. We do try to import classes, but that won't
always be successful.

=head2 default_exports

C<HashRef> of symbols we think a class exports by default. That is an
invocation like:

    use Foo;

will import all of these symbols for you.

=head2 default_imports_match_exports

Returns true if import and export names match. Used to determine if we should
dump a one or two column table of import and export names.

=head2 errors

An C<ArrayRef> of errors which probably happened when we got creative with
importing modules.

=head2 export_fail

An C<ArrayRef> of the contents of C<@EXPORT_FAIL>. This would only apply to
modules using L<Exporter>.

=head2 export_tags

An C<ArrayRef> of the contents of C<@EXPORT_TAGS>. This would only apply to
modules using L<Exporter>.

=head2 has_errors

Returns true if C<errors()> has data to return.

=head2 has_export_fail

Returns true if C<export_fail()> has data to return.

=head2 has_export_tags

Returns true if C<export_tags()> has data to return.

=head2 is_exporter

Returns true if we think this class uses L<Exporter>.

=head2 is_sub_exporter

Returns true if we think this class uses L<Sub::Exporter>.
