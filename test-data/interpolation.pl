use strict;
use warnings;

use Encode;

my $code = 'foo';
warn "-- @{[encode 'UTF-8', $code]}\n\n";
