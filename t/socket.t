use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];

my ($doc) = doc(
    filename => 'test-data/socket.pl',
);

my $expected = <<'EOF';
use strict;
use warnings;

use IO::Socket::INET ();
use Socket qw( SO_REUSEPORT SOL_SOCKET );

foo( SO_REUSEPORT, SOL_SOCKET );
sub foo { }
EOF

is(
    $doc->tidied_document,
    $expected,
    'Two modules with the same exports do not get conflated'
);

done_testing;
