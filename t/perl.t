use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is' ];

my $doc
    = App::perlimports::Document->new(
    filename => 'test-data/perl-version.pl' );
my $expected = <<'EOF';
use strict;
use warnings;
use 5.008001;
EOF

is( $doc->tidied_document, $expected, 'perl use statement ignored' );

done_testing();
