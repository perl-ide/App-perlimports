use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'is' ];
use Test::Needs qw( DateTime );

my ( $doc, $logs ) = doc( filename => 'test-data/datetime.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use DateTime ();

my $dt = DateTime->now;
EOF

is( $doc->tidied_document, $expected, 'DateTime does not import' );

done_testing();
