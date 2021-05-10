use strict;
use warnings;

use Test::Needs { perl => 5.020 };

use lib 't/lib';
use TestHelper qw( doc );
use Test::More import => [ '$TODO', 'done_testing', 'is' ];

my $expected = <<'EOF';
use strict;
use warnings;

use v5.20;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use signatures;

use HTTP::Status qw( HTTP_CONTINUE );

## no critic (Subroutines::ProhibitSubroutinePrototypes)
sub one ( $continue  = HTTP_CONTINUE, $foo = 'bar' ) {
    return $continue;
}
EOF

TODO: {
    local $TODO = 'need to handle symbols used in sigatures';
    my ($doc) = doc( filename => 'test-data/signatures.pl' );
    is( $doc->tidied_document, $expected, 'tidied_document' );
}

done_testing;
