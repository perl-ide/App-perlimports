use strict;
use warnings;

use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( done_testing )];
use Test::Needs { 'HTTP::Status' => 6.28, perl => 5.020 };

use lib 't/lib';
use TestHelper qw( doc );

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

my ( $doc, $logs )
    = doc( filename => 'test-data/signatures.pl', preserve_unused => 0 );
eq_or_diff( $doc->tidied_document, $expected, 'tidied_document' );

done_testing;
