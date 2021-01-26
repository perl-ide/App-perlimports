use strict;
use warnings;

use lib 't/lib';

use App::perlimports::ExportInspector ();
use Test::More import => [qw( done_testing is_deeply ok )];

my $ei = App::perlimports::ExportInspector->new(
    module_name => 'ViaSubExporter' );

ok( !$ei->has_errors, 'no errors' );
is_deeply(
    $ei->combined_exports,
    { bar => 'bar', foo => 'foo', },
    'combined exports'
);

done_testing();
