use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper qw( source2pi );
use Test::More import => [ 'diag', 'done_testing', 'is', 'ok' ];

{
    my $e = source2pi(
        'test-data/geo-ip.pl',
        'use Geo::IP;',
    );

    is(
        $e->formatted_ppi_statement,
        q{use Geo::IP qw( GEOIP_MEMORY_CACHE GEOIP_STANDARD );},
        'module not ignored'
    );
}

{
    my $doc = App::perlimports::Document->new(
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
    ok( $doc->_is_ignored('Geo::IP'), 'Geo::IP flagged as ignored' );
}

done_testing();
