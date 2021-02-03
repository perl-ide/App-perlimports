use strict;
use warnings;

use Test2::V0 '-no_pragmas' => 1, '!meta', 'diag', 'done_testing', 'is';

my $foo = 'foo';
is($foo, 'foo');
diag $foo;

done_testing;
