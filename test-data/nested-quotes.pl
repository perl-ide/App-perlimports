use strict;
use warnings;

use Path::Tiny;

my $thing = qq{content="${ \( path('one/two.txt')->stringify )}"};
print "$thing\n";
