#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'ok' ];

my $source_text
    = q{use Test::More do { $ENV{COVERAGE} ? ( skip_all => 'skip under Devel::Cover' ) : () };};

my $e = source2pi(
    'test-data/skip-all.t',
    $source_text,
);

ok( !$e->_is_ignored, 'noop' );

is(
    $e->formatted_ppi_statement,
    $source_text,
    'formatted_ppi_statement'
);

done_testing();
