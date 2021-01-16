use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is' ];

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
    my $e = source2pi(
        'test-data/geo-ip.pl',
        'use Geo::IP;',
        { ignored_modules => ['Geo::IP'] },
    );
    is(
        $e->formatted_ppi_statement,
        q{use Geo::IP;},
        'module ignored'
    );
}

done_testing();
