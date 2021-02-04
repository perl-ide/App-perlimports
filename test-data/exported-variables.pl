use strict;
use warnings;

use DDP;
use Local::ViaExporter qw( %foo @foo );

print $foo[0];
print $foo{bar};
print ${foo};
