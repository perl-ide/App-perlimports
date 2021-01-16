use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'like', 'ok' ];

my $source_text = 'use Local::Module::Does::Not::Exist::At::All;';

my $e = source2pi(
    'test-data/geo-ip.pl',
    $source_text,
);

is(
    $e->formatted_ppi_statement,
    $source_text,
    'formatted_ppi_statement unchanged'
);

ok( $e->has_errors, 'has_errors' );
like(
    $e->errors->[0], qr{Can't locate Local/Module/Does/Not},
    'error message'
);

done_testing();
