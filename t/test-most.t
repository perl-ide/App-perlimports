use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use Test::More (
    import => [ 'diag', 'done_testing', 'is', 'is_deeply', 'ok', 'subtest' ] );

for my $module ( 'Test::More', 'Test::Most' ) {
    subtest $module => sub {
        my $e = App::perlimports->new(
            filename    => 'test-data/test-most.t',
            source_text => "use $module;",
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
