#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc source2pi );
use Test::More import => [qw( done_testing is ok )];
use Test::Needs qw( Geo::IP );

{
    my $e = source2pi(
        'test-data/geo-ip.pl',
        'use Geo::IP;',
    );

    is(
        $e->formatted_ppi_statement,
        'use Geo::IP qw( GEOIP_MEMORY_CACHE GEOIP_STANDARD );',
        'module not ignored'
    );
}

{
    my ($doc) = doc(
        filename       => 'test-data/geo-ip.pl',
        ignore_modules => ['Geo::IP'],
    );

    my $expected = <<'EOF';
use strict;
use warnings;

use Geo::IP;

my $enable_cache = 0;
my $standard     = GEOIP_STANDARD;

my $cache = $enable_cache ? GEOIP_MEMORY_CACHE : 0;
EOF

    is(
        $doc->tidied_document,
        $expected,
        'module ignored'
    );
    my $includes = $doc->ppi_document->find('PPI::Statement::Include');
    is( $includes->[2]->module, 'Geo::IP' );
    ok( $doc->_is_ignored( $includes->[2] ), 'Geo::IP flagged as ignored' );
}

done_testing();
