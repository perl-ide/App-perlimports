use strict;
use warnings;

use lib 'test-data/lib';

use App::perlimports::ExportInspector ();
use Test::More import => [qw( done_testing is_deeply ok )];

my $ei = App::perlimports::ExportInspector->new(
    module_name => 'Local::ViaSubExporter' );

ok( !$ei->has_errors, 'no errors' );
is_deeply(
    $ei->explicit_exports,
    { bar => 'bar', foo => 'foo', },
    'explicit exports'
);

done_testing();
