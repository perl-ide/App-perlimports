use strict;
use warnings;

use Carp;    ## no perlimports

use POSIX;

## no perlimports
use Cwd;
use Digest;
## use perlimports

use Encode;

print decode(
    'utf8',
    sprintf(
        'hey %s', encode( 'utf8', 'Sofia Margareta Götschenhjelm-Helin' )
    )
);
