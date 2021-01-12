package RequireExporter;

use strict;
use warnings;

require Exporter;
our @EXPORT = qw(foo);

sub foo { return 'from sub foo' }

1;
