#!perl

use strict;
use warnings;

use lib 't/lib';

use List::Util qw( none );
use TestHelper qw( doc );
use Test::More import => [qw( done_testing is ok )];

# Test the minimal example from the issue
my ( $doc1, $logs1 ) = doc(
    filename => 'test-data/double-quoted-q.pl',
);

my $tidied1 = $doc1->tidied_document;

ok(
    do {
        none { $_->{level} eq 'error' } @$logs1;
    },
    'no errors in logs for double-quoted "q"'
);

ok( defined $tidied1, 'tidied_document returns a result for double-quoted "q"' );

# Test the real-world pack("qq") example
my ( $doc2, $logs2 ) = doc(
    filename => 'test-data/pack-qq.pl',
);

my $tidied2 = $doc2->tidied_document;

ok(
    do {
        none { $_->{level} eq 'error' } @$logs2;
    },
    'no errors in logs for pack("qq")'
);

ok( defined $tidied2, 'tidied_document returns a result for pack("qq")' );

# Make sure the tidied document still contains the pack statement
like( $tidied2, qr/pack\("qq"/, 'pack statement is preserved' );

done_testing;
