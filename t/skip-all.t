#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'ok' ];

my $e = source2pi(
    'test-data/skip-all.t',
    q{use Test::More 0.93 skip_all => 'Test is broken', tests => 3, foo => ['bar'] ;},
);

ok( !$e->_is_ignored, 'not an ignored module' );
my $expected = <<'EOF';
use Test::More 0.93 (
    foo      => ['bar'],
    import   => [ 'is', 'is_deeply', 'ok' ],
    skip_all => 'Test is broken',
    tests    => 3
);
EOF

chomp $expected;

is(
    $e->formatted_ppi_statement,
    $expected,
    'formatted_ppi_statement'
);

done_testing();
