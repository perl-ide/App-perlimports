use strict;
use warnings;

use lib 't/lib';

use App::perlimports::CLI ();
use Capture::Tiny qw( capture );
use Test::More import => [ 'done_testing', 'is' ];

my $expected = <<'EOF';
use strict;
use warnings;

use CustomImport qw( -ignore blib -ignore \\wB\\w );
EOF

local @ARGV = ( '-f', 'test-data/switches-in-import.pl', );
my $cli = App::perlimports::CLI->new;
my ($stdout) = capture {
    $cli->run;
};
is( $stdout, $expected, 'module switches preserved' );

done_testing();
