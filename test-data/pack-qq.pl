use strict;
use warnings;

use IO::Socket::INET;

my $sock = IO::Socket::INET->new;

my $timeout = pack("qq", 10, 0);
$sock->sockopt(SO_RCVTIMEO, $timeout);
