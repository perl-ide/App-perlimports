use strict;
use warnings;

use App::perlimports ();
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

subtest 'Types::Standard' => sub {
    my $e = App::perlimports->new(
        filename    => 'lib/App/perlimports.pm',
        source_text => 'use Types::Standard;',
    );
    is(
        $e->_module_name, 'Types::Standard',
        '_module_name'
    );
    ok( $e->_is_ignored, 'noop' );
};

subtest 'Test::RequiresInternet' => sub {
    my $e = App::perlimports->new(
        filename    => 'test-data/noop.t',
        source_text =>
            q{use Test::RequiresInternet ('www.example.com' => 80 );},
    );
    is(
        $e->_module_name, 'Test::RequiresInternet',
        '_module_name'
    );

    ok( $e->_is_ignored, 'noop' );
    is(
        $e->formatted_ppi_statement,
        q{use Test::RequiresInternet ('www.example.com' => 80 );}
    );
};

done_testing();
