use strict;
use warnings;

use Test::More import => [ 'is', 'is_deeply', 'ok' ],
    skip_all => 'Test is broken', tests => 28;

ok(1);
is( 1, 1 );
is_deeply( ['foo'], ['bar'] );
