use strict;
use warnings;

use lib 't/lib';
use Test::More import => [ 'done_testing', 'is', 'is_deeply' ];
use TestHelper qw( source2pi );

my $source_text = 'use Getopt::Long qw( $REQUIRE_ORDER $RETURN_IN_ORDER );';
my $include     = source2pi( 'test-data/variable.pl', $source_text );

is(
    $include->formatted_ppi_statement,
    $source_text,
    'variable in block is found'
);

is_deeply(
    $include->_document->interpolated_symbols,
    { '$REQUIRE_ORDER' => 1, '$RETURN_IN_ORDER' => 1, }
);

done_testing();
