use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::Fatal qw( exception );
use Test::More import => [ 'done_testing', 'is', 'like', 'ok' ];

my $source_text = 'use Local::Module::Does::Not::Exist::At::All;';

my $e = source2pi(
    'test-data/geo-ip.pl',
    $source_text,
);

like(
    exception { $e->formatted_ppi_statement },
    qr{Can't locate Local/Module},
    'exception on module not found'
);

done_testing();
