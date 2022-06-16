use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing )];

my ( $doc, $log ) = doc( filename => 'test-data/sort.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use Local::Sort qw( $AAA $AAA_2FA bbb @BBB %CCC );

bbb();
bbb_2fa();

if ( defined $AAA || defined $AAA_2FA || scalar @BBB || keys %CCC ) {
    print 'defined';
}
EOF

eq_or_diff( $doc->tidied_document, $expected, 'sorted' );

done_testing();
