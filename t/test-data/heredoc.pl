use strict;
use warnings;

use Test::More;

my $got = 'PUT http://www.example.com' . "\n";

is( $got, <<"EOT", 'put' );
PUT http://www.example.com
EOT

done_testing();
