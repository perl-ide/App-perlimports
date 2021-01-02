use strict;
use warnings;

use Geo::IP;

my $enable_cache = 0;
my $standard     = GEOIP_STANDARD;

my $cache = $enable_cache ? GEOIP_MEMORY_CACHE : 0;
