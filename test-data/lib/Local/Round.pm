package Local::Round;
use parent 'Exporter';

use strict;
use warnings;

use Math::Round qw( nearest );
our @EXPORT_OK = qw(round);

sub round {
    my ( $number, $places ) = @_;
    return nearest( 10**-$places, $number );
}

1;
