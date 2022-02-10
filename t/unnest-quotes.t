use strict;
use warnings;

use lib 't/lib';

use List::Util qw( none );
use TestHelper qw( doc );
use Test::More import => [qw( done_testing ok )];

my @errors;

my ( $doc, $logs ) = doc(
    filename => 'test-data/unnest-quotes.pl',
);
$doc->tidied_document;

ok(
    do {
        none { $_->{level} eq 'error' } @$logs;
    },
    'no errors in logs'
);

done_testing;
