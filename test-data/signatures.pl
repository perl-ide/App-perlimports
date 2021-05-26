use strict;
use warnings;

use v5.20;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use signatures;

use HTTP::Status qw( HTTP_CONTINUE );

## no critic (Subroutines::ProhibitSubroutinePrototypes)
sub one ( $continue  = HTTP_CONTINUE, $foo = 'bar', $two = HTTP_OK() ) {
    return $continue;
}
