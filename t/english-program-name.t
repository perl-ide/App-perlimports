use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];

# GH #97: English exports typeglobs like *PROGRAM_NAME, but a single-slot
# import such as $PROGRAM_NAME must be preserved, not expanded.
my ($doc) = doc( filename => 'test-data/english-program-name.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use English qw( $PROGRAM_NAME );

print "$PROGRAM_NAME\n";
EOF

is(
    $doc->tidied_document,
    $expected,
    '$PROGRAM_NAME slot import is preserved, not expanded to *PROGRAM_NAME'
);

done_testing();
