use strict;
use warnings;

use File::Temp qw(tempfile);
use List::Util qw( any );
use File::Temp qw(tempdir);

sub foo {
    my $dir  = tempdir();
    my $file = tempfile();
    return any { $_ > 1 } ( 0 .. 2 );
}
