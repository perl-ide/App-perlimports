use strict;
use warnings;

use Test::More import => [qw( can_ok cmp_ok diag done_testing is isa_ok isnt like note ok pass subtest unlike )];

can_ok( 'Foo', 'bar' );
cmp_ok( 1, '==', 1 );
diag('hi');
is( 1, 1 );
isa_ok( \1, 'SCALAR' );
isnt( 1, 2 );
like( 'a', qr/a/ );
note('hi');
ok(1);
pass('ok');
subtest 'x' => sub { ok(1) };
unlike( 'a', qr/b/ );

done_testing();
