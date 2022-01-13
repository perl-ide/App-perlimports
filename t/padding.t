#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];

my ($doc) = doc(
    filename => 'test-data/carp.pl',
    padding  => 0,
);

my $expected = <<'EOF';
use strict;
use warnings;

use Carp qw(croak verbose);

croak('oof');
EOF

is( $doc->tidied_document, $expected, 'list is not padded' );

done_testing();
