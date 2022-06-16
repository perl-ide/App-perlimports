use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( diag done_testing )];

my ( $doc, $log )
    = doc( filename => 'test-data/missing-semicolon-in-import.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use Carp use POSIX;
EOF

eq_or_diff(
    $doc->tidied_document,
    $expected,
    'broken imports are untouched'
) || do { require Data::Dumper; diag Data::Dumper::Dumper($log); };

done_testing();
