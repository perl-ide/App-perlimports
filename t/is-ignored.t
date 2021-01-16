use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

subtest 'Types::Standard' => sub {
    my $e = source2pi(
        'lib/App/perlimports.pm',
        'use Types::Standard;',
    );
    is(
        $e->_module_name, 'Types::Standard',
        '_module_name'
    );
    ok( $e->_is_ignored, 'noop' );
};

subtest 'Test::RequiresInternet' => sub {
    my $e = source2pi(
        'test-data/noop.t',
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
