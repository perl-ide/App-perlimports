use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More;

my ($doc) = doc(
    filename => 'test-data/dupes.pl',
);

my $expected = <<'EOF';
use strict;
use warnings;

use File::Temp qw( tempdir tempfile );
use List::Util qw( any );

sub foo {
    my $dir  = tempdir();
    my $file = tempfile();
    return any { $_ > 1 } ( 0 .. 2 );
}
EOF

is(
    $doc->tidied_document,
    $expected,
    'duplicate use statement removed'
);

done_testing;
