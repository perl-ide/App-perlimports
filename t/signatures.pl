use strict;
use warnings;

use Test::Needs { perl => 5.020 };

use lib 't/lib';
use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'is' ];

my $expected = <<'EOF';
use strict;
use warnings;

use v5.20;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use signatures;

use FindBin qw( $Bin );
use HTTP::Status qw( HTTP_CONTINUE HTTP_OK );

## no critic (Subroutines::ProhibitSubroutinePrototypes)
sub one ( $continue  = HTTP_CONTINUE, $foo = 'bar', $two = HTTP_OK() ) {
    return $continue;
}

sub two ( $cwd = $Bin ) { }
EOF

my ( $doc, $logs ) = doc( filename => 'test-data/signatures.pl' );
is( $doc->tidied_document, $expected, 'tidied_document' );

done_testing;
