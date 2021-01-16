use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

for my $module ( 'Test::More', 'Test::Most' ) {
    subtest $module => sub {
        my $e = source2pi(
            'test-data/test-most.t',
            "use $module;",
        );

        ok( $e->_isa_test_builder_module, '_isa_test_builder_module' );
        is(
            $e->formatted_ppi_statement,
            qq{use $module import => [ qw( done_testing ) ];},
            'formatted_ppi_statement'
        );
    };
}

done_testing();
