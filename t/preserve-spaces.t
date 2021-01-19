use strict;
use warnings;

use lib 't/lib';

use Test::More import => [ 'done_testing', 'is', 'subtest' ];
use TestHelper qw( source2pi );

my $source_text = 'use Carp    ();';
my $e           = source2pi( 'test-data/preserve-spaces.pl', $source_text );

is(
    $e->formatted_ppi_statement,
    $source_text,
    'arbitrary spacing is preserved'
);

#use DDP;
#p $e;

done_testing();
