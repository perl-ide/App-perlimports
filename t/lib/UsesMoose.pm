package UsesMoose;

use Moose;

has foo => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
1;
