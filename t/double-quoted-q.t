#!perl

use strict;
use warnings;

use lib 't/lib';

use List::Util qw( none );
use TestHelper qw( doc );
use Test::More import => [qw( done_testing like ok )];

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

ok(
    do {
        none { $_->{message} && $_->{message} =~ /undefined value/ } @$logs1;
    },
    'no undefined value errors for double-quoted "q"'
);

ok(
    defined $tidied1,
    'tidied_document returns a result for double-quoted "q"'
);

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

ok(
    do {
        none { $_->{message} && $_->{message} =~ /undefined value/ } @$logs2;
    },
    'no undefined value errors for pack("qq")'
);

ok( defined $tidied2, 'tidied_document returns a result for pack("qq")' );

# Make sure the tidied document still contains the pack statement
like( $tidied2, qr/pack\("qq"/, 'pack statement is preserved' );

# Test various quote-like strings
my ( $doc3, $logs3 ) = doc(
    filename => 'test-data/various-quote-strings.pl',
);

my $tidied3 = $doc3->tidied_document;

ok(
    do {
        none { $_->{level} eq 'error' } @$logs3;
    },
    'no errors in logs for various quote-like strings'
);

ok(
    do {
        none { $_->{message} && $_->{message} =~ /undefined value/ } @$logs3;
    },
    'no undefined value errors for various quote-like strings'
);

ok(
    defined $tidied3,
    'tidied_document returns a result for various quote-like strings'
);

# Verify that real quote operators are preserved in output
like( $tidied3, qr/q\{single quoted string\}/,  'q{} operator preserved' );
like( $tidied3, qr/qq\[double quoted string\]/, 'qq[] operator preserved' );
like( $tidied3, qr/qw\(list of words\)/,        'qw() operator preserved' );

done_testing;
