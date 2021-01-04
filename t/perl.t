use strict;
use warnings;

use App::perlimports ();
use Test::More import => [ 'done_testing', 'is', 'ok' ];

my $source_text = 'use 5.008001;';

my $e = App::perlimports->new(
    filename    => 'test-data/geo-ip.pl',
    source_text => $source_text,
);

is(
    $e->formatted_ppi_statement,
    $source_text,
    'formatted_ppi_statement unchanged'
);

ok( !$e->has_errors, 'empty has_errors' );

done_testing();

