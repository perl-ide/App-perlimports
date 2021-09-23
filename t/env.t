use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'skip' ];
use Test::Needs qw( Env );

my ($doc) = doc( filename => 'test-data/env.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use Env qw( @PATH );

print "$_\n" for @PATH;
EOF

SKIP: {
    skip 'Cannot deal with Env.pm yet';

    eq_or_diff(
        $doc->tidied_document,
        $expected
    );
}

done_testing();
