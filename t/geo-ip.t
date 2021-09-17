#!/usr/bin/env perl

use strict;
use warnings;

# misses import in ternary

use lib 't/lib';

use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'is_deeply' ];
use Test::Needs qw( Geo::IP );

my $e = source2pi(
    'test-data/geo-ip.pl',
    'use Geo::IP;',
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
