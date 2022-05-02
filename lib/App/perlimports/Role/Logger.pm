package App::perlimports::Role::Logger;

use Moo::Role;

our $VERSION = '0.000038';

use Types::Standard qw( InstanceOf );

has logger => (
    is        => 'ro',
    isa       => InstanceOf ['Log::Dispatch'],
    predicate => '_has_logger',
    writer    => 'set_logger',
);

1;

# ABSTRACT: Provide a logger attribute to App::perlimports objects
