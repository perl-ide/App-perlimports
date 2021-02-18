package App::perlimports::Role::Logger;

use Moo::Role;

use Log::Dispatch ();
use Types::Standard qw( ArrayRef InstanceOf );

has logger => (
    is      => 'ro',
    isa     => InstanceOf ['Log::Dispatch'],
    lazy    => 1,
    default => sub {
    },
);

has log_as_array => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub { [] },
);

sub _build_logger {
    my $self   = shift;
    my $logger = Log::Dispatch->new(
        outputs => [
            [ 'Screen', min_level => 'debug' ],
        ],
    );

    return $logger unless $ENV{HARNESS_ACTIVE};

    require Log::Dispatch::Array;

    $logger->add(
        Log::Dispatch::Array->new(
            name      => 'text_table',
            min_level => 'debug',
            array     => $self->log_as_array,
        )
    );

    return $logger;
}

1;
