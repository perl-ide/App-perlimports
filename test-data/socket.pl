use strict;
use warnings;

use IO::Socket::INET;
use Socket qw(SO_REUSEPORT SOL_SOCKET);

foo( SO_REUSEPORT, SOL_SOCKET );
sub foo { }
