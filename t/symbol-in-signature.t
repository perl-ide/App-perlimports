use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [ '$TODO', 'done_testing', 'is' ];

my ($doc) = doc( filename => 'test-data/symbol-in-signature.pl' );
my $expected = <<'EOF';
use strict;
use warnings;

use HTTP::Status qw( HTTP_OK );

sub foo ( $status = HTTP_OK ) {}
EOF

TODO: {
    local $TODO = 'Cannot understand signatures yet';
    is( $doc->tidied_document, $expected, 'symbol in signature found' );
}

done_testing();
