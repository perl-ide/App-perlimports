use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [ 'diag', 'done_testing', 'is_deeply' ];

my ($doc) = doc( filename => 'test-data/interpolation.pl' );

is_deeply(
    $doc->interpolated_symbols, { '$code' => 1, encode => 1 },
    'vars'
);

done_testing();
