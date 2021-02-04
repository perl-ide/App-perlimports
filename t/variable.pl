use strict;
use warnings;

use Test::More import => [ 'done_testing', 'is', 'subtest' ];
use TestHelper qw( source2pi );

my $source_text = 'use Getopt::Long qw( $REQUIRE_ORDER $RETURN_IN_ORDER );';
my $e           = source2pi( 'test-data/variable.pl', $source_text );

is(
    $e->formatted_ppi_statement,
    $source_text,
    'variable in block is found'
);

done_testing();
