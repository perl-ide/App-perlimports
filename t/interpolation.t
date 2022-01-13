use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper qw( doc );
use Test::More import => [qw( done_testing )];

my ($doc) = doc( filename => 'test-data/interpolation.pl' );

eq_or_diff(
    $doc->interpolated_symbols, { '$code' => 1, encode => 1 },
    'vars'
);

done_testing();
