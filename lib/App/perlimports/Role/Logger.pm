package App::perlimports::Role::Logger;

use Moo::Role;

use Log::Dispatch ();
use Types::Standard qw( ArrayRef InstanceOf );

has logger => (
    is      => 'ro',
    isa     => InstanceOf ['Log::Dispatch'],
    lazy    => 1,
    builder => '_build_logger',
);

has log_as_array => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub { [] },
);

sub _build_logger {
    my $self   = shift;
    my @caller = caller(2);
    require Carp;
    use Carp;
    Carp::croak();
    return Log::Dispatch->new(
        outputs => [
            [ 'Screen', min_level => 'debug' ],
        ],
    );
}

1;
