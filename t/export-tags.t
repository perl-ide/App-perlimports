use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( done_testing )];

my ($doc) = doc( filename => 'test-data/export-tags.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use HTTP::Status qw(
    HTTP_I_AM_A_TEAPOT
    HTTP_NO_CODE
    HTTP_REQUEST_ENTITY_TOO_LARGE
);

my $pot  = HTTP_I_AM_A_TEAPOT;
my $big  = HTTP_REQUEST_ENTITY_TOO_LARGE;
my $what = HTTP_NO_CODE;
EOF

eq_or_diff(
    $doc->tidied_document, $expected,
    'export tags converted to symbols'
);

done_testing();
