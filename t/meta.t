use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( Test2::V0 );

my ($doc) = doc(
    filename => 'test-data/meta.t',
);

my $expected = <<'EOF';
use strict;
use warnings;

use Test2::V0 qw( !meta done_testing ok );

ok(1);

done_testing;
EOF

is(
    $doc->tidied_document,
    $expected,
    '!meta preserved in import'
);

done_testing;
