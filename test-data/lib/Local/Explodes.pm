package Local::Explodes;

use strict;
use warnings;

BEGIN {
    die 'oof';
}

require Exporter;
our @EXPORT = qw(foo);

sub foo { return 'from sub foo' }

1;
