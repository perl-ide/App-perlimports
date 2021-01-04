use strict;
use warnings;

use App::perlimports ();
use Test::More       ( import => [ 'done_testing', 'is', 'is_deeply' ] );

{
    my $e = App::perlimports->new(
        filename    => 'test-data/geo-ip.pl',
        source_text => 'use Geo::IP;',
    );

    is(
        $e->formatted_ppi_statement,
        q{use Geo::IP qw( GEOIP_MEMORY_CACHE GEOIP_STANDARD );},
        'module not ignored'
    );
}

{
    my $e = App::perlimports->new(
        filename        => 'test-data/geo-ip.pl',
        ignored_modules => ['Geo::IP'],
        source_text     => 'use Geo::IP;',
    );
    is(
        $e->formatted_ppi_statement,
        q{use Geo::IP;},
        'module ignored'
    );
}

done_testing();
