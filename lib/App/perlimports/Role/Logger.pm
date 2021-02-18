package App::perlimports::Role::Logger;

use Moo::Role;

use Types::Standard qw( InstanceOf );

has logger => (
    is        => 'ro',
    isa       => InstanceOf ['Log::Dispatch'],
    predicate => '_has_logger',
);

1;
