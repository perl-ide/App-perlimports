use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use Test::More import => [ 'done_testing', 'ok', 'subtest' ];
use TestHelper qw( inspector );
use Test::Needs qw( Data::Printer );

subtest 'Data::Printer' => sub {
    my ($inspector) = inspector('Data::Printer');
    ok( exists $inspector->implicit_exports->{np}, 'np() imported' );
    ok( exists $inspector->implicit_exports->{p},  'p() imported' );
};

done_testing();
