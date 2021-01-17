use strict;
use warnings;

use lib 't/lib';

use Test::More import => [ 'done_testing', 'is', 'subtest' ];
use TestHelper qw( source2pi );

subtest 'english' => sub {
    my $source_text = 'use English qw( -no_match_vars );';
    my $e           = source2pi( 'test-data/english.pl', $source_text );

    is(
        $e->formatted_ppi_statement,
        $source_text,
        '-no-match-vars is preserved'
    );
};

done_testing();
