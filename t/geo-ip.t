use strict;
use warnings;

# misses import in ternary

use App::perlimports ();
use Test::More import => [ 'done_testing', 'is', 'is_deeply' ];

my $e = App::perlimports->new(
    filename    => 'test-data/geo-ip.pl',
    source_text => 'use Geo::IP;',
);

is_deeply(
    $e->_imports, [ 'GEOIP_MEMORY_CACHE', 'GEOIP_STANDARD' ],
    '_imports'
);
is(
    $e->formatted_ppi_statement,
    q{use Geo::IP qw( GEOIP_MEMORY_CACHE GEOIP_STANDARD );},
    'formatted_ppi_statement'
);

done_testing();
