use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is' ];

my $doc
    = App::perlimports::Document->new( filename => 'test-data/english.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use English qw( -no_match_vars );
EOF

is( $doc->tidied_document, $expected, '-no-match-vars is preserved' );

done_testing();
