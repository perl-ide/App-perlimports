use strict;
use warnings;

use App::perlimports ();
use Test::More       ( import => [ 'done_testing', 'is', 'ok' ] );

my $e = App::perlimports->new(
    filename    => 'test-data/skip-all.t',
    source_text =>
        q{use Test::More 0.93 skip_all => 'Test is broken', tests => 3, foo => ['bar'] ;},
);

ok( !$e->_is_ignored, 'noop' );
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
