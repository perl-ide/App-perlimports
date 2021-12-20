use strict;
use warnings;

use Local::Sort qw( $AAA_2FA bbb bba_2fa $AAA @BBB %CCC );

bbb();
bbb_2fa();

if ( defined $AAA || defined $AAA_2FA || scalar @BBB || keys %CCC ) {
    print 'defined';
}
