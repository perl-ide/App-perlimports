use strict;
use warnings;

use lib 't/lib';

# misses import in ternary

use App::perlimports ();
use Test::More import => [qw( done_testing is is_deeply ok )];

my $e = App::perlimports->new(
    filename    => 't/test-data/geo-ip.pl',
    source_text => 'use Geo::IP;',
);

is_deeply(
    $e->_imports, [ 'GEOIP_MEMORY_CACHE', 'GEOIP_STANDARD' ],
    '_imports'
);
is(
    $e->formatted_import_statement,
    q{use Geo::IP qw( GEOIP_MEMORY_CACHE GEOIP_STANDARD );},
    'formatted_import_statement'
);

done_testing();
