use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use App::perlimports::Importer::Other ();
use Test::More import =>
    [ 'done_testing', 'is', 'is_deeply', 'ok', 'subtest' ];
use TestHelper qw( logger );
use Test::Needs qw(
    Data::Printer
);

subtest 'Data::Printer' => sub {
    my $log = [];
    my ($inspection)
        = App::perlimports::Importer::Other::maybe_get_exports(
        'Data::Printer', logger($log) );
    ok( exists $inspection->default_exports->{np}, 'np() imported' );
    ok( exists $inspection->default_exports->{p},  'p() imported' );
};

done_testing();
