use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'is_deeply', 'ok' ];

my $e = source2pi(
    't/lib/UsesMoo.pm',
    'use Moo;',
);
is(
    $e->_module_name(), 'Moo',
    '_module_name'
);

ok( $e->_is_ignored, '_is_ignored' );
is_deeply( $e->_imports, [], '_imports' );
is(
    $e->formatted_ppi_statement,
    q{use Moo;},
    'formatted_ppi_statement'
);

done_testing();
