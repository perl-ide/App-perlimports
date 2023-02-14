#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing )];

my ($doc) = doc(
    filename        => 'test-data/preserve-some-padding.pl',
    tidy_whitespace => 1,
);

my $expected = <<'EOF';
use strict;
use warnings;

use Carp    qw( croak verbose );

croak('oof');
EOF

eq_or_diff( $doc->tidied_document, $expected, 'list is not padded' );

done_testing();
