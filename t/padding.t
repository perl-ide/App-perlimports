#!/usr/bin/env perl

use strict;
use warnings;

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is' ];

my $doc = App::perlimports::Document->new(
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
