use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper qw( doc );
use Test::More import => ['done_testing'];

my ( $doc, $log ) = doc( filename => 'test-data/sort.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use Local::Sort qw( $AAA bbb @BBB %CCC );

bbb();

if ( defined $AAA || scalar @BBB || keys %CCC ) {
    print 'defined';
}
EOF

eq_or_diff( $doc->tidied_document, $expected, 'sorted' );

done_testing();
