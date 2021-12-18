use strict;
use warnings;

use Local::Sort qw( bbb $AAA @BBB %CCC );

bbb();

if ( defined $AAA || scalar @BBB || keys %CCC ) {
    print 'defined';
}
