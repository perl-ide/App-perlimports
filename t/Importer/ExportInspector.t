use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::ExportInspector ();
use TestHelper qw( logger );
use Test::More import => [qw( done_testing is_deeply ok )];

my $ei = App::perlimports::ExportInspector->new(
    logger      => logger( [] ),
    module_name => 'Local::ViaSubExporter'
);

ok( !$ei->has_errors, 'no errors' );
is_deeply(
    $ei->explicit_exports,
    { bar => 'bar', foo => 'foo', },
    'explicit exports'
);

done_testing();
