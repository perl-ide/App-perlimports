package App::perlimports::ExportInspector::Inspection;

use Moo;

use List::Util qw( any );
use MooX::StrictConstructor;
use Sub::HandlesVia;
use Types::Standard qw( ArrayRef Bool HashRef );

has all_exports => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        has_all_exports => 'keys',
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
    is  => 'ro',
    isa => HashRef,
);

has export_fail => (
    is        => 'ro',
    isa       => ArrayRef,
    predicate => 'has_export_fail',
);

has export_tags => (
    is        => 'ro',
    isa       => HashRef,
    predicate => 'has_export_tags',
);

has errors => (
    is        => 'ro',
    isa       => ArrayRef,
    predicate => 'has_errors',
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

has is_moose_type_class => (
    is        => 'ro',
    isa       => Bool,
    predicate => 'has_is_moose_type_class',
);

sub _build_is_moose_class {
    my $self = shift;

    if ( !$self->has_class_isa || !$self->has_all_exports ) {
        return 0;
    }

    return any { $_ eq 'Moose::Object' || $_ eq 'Test::Class::Moose' }
    @{ $self->class_isa };
}
1;
