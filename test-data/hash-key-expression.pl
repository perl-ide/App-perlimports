use strict;
use warnings;

use HTTP::Status qw(is_info);

my %foo;
my $code = 100;
$foo{ is_info $code } = 'bar';
