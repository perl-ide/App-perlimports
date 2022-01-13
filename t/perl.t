use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];

my ($doc) = doc( filename => 'test-data/perl-version.pl' );
my $expected = <<'EOF';
use strict;
use warnings;
use 5.008001;
EOF

is( $doc->tidied_document, $expected, 'perl use statement ignored' );

done_testing();
