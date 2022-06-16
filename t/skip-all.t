#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use TestHelper        qw( source2pi );
use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( done_testing ok )];

my $e = source2pi(
    'test-data/skip-all.t',
    q{use Test::More 0.93 skip_all => 'Test is broken', tests => 3, foo => ['bar'] ;},
);

ok( !$e->_is_ignored, 'not an ignored module' );
my $expected = <<'EOF';
use Test::More 0.93 import => [qw( is is_deeply ok )],
  foo                      => ['bar'],
  skip_all                 => 'Test is broken',
  tests                    => 3;
EOF

chomp $expected;

eq_or_diff(
    $e->formatted_ppi_statement . q{},
    $expected,
    'formatted_ppi_statement'
);

done_testing();
