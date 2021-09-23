use strict;
use warnings;

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is' ];

my $doc = App::perlimports::Document->new(
    filename => 'test-data/config-in-import.pl' );

my $expect = <<'EOF';
use strict;
use warnings;

use Getopt::Long qw(
    :config
    no_auto_abbrev
    no_ignore_case
    bundling
    pass_through
);
EOF

is( $doc->tidied_document, $expect, 'config options in import preserved' );

done_testing();
