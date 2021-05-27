use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [ '$TODO', 'done_testing', 'is' ];

my ($doc) = doc( filename => 'test-data/lib/Local/WithInnerPkg.pm' );
my $expected = <<'EOF';
use strict;
use warnings;

package Local::WithInnerPkg;

use HTTP::Status qw( HTTP_OK );

sub foo {
    HTTP_OK();
}
1;

package MyInnerPkgOne;

use HTTP::Status qw( HTTP_CREATED );

sub foo {
    HTTP_CREATED();
}
1;

package MyInnerPkgTwo;

use HTTP::Status qw( HTTP_ACCEPTED );

sub foo {
    HTTP_ACCEPTED();
}

1;
EOF

TODO: {
    local $TODO = 'Cannot yet handle inner packages';
    is( $doc->tidied_document, $expected, 'inner packages handled' );
}

done_testing();
