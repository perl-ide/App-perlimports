use strict;
use warnings;

use lib 't/lib';

use App::perlimports::ExportInspector ();
use Test::More;

my $ei = App::perlimports::ExportInspector->new(
    module_name => 'ViaSubExporter' );

ok( !$ei->has_errors, 'no errors' );
is_deeply(
    $ei->combined_exports,
    { bar => 'bar', foo => 'foo', },
    'combined exports'
);

done_testing();
