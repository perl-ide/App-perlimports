use strict;
use warnings;

use App::perlimports ();
use Test::More import => [ 'done_testing', 'is', 'like', 'ok' ];

my $source_text = 'use Local::Module::Does::Not::Exist::At::All;';

my $e = App::perlimports->new(
    filename    => 'test-data/geo-ip.pl',
    source_text => $source_text,
);

is(
    $e->formatted_ppi_statement,
    $source_text,
    'formatted_ppi_statement unchanged'
);

ok( $e->has_errors, 'has_errors' );
like( $e->errors->[1], qr{Cannot find}, 'error message' );

done_testing();
