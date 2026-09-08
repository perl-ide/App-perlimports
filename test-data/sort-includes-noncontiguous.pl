use strict;
use Foo;
use Bar;

my $x = 1;

sub thing {
    require Zzz;
    return $x;
}

1;
