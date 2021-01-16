use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import =>
    [ 'diag', 'done_testing', 'is', 'is_deeply', 'ok', 'subtest' ];

subtest 'Moose' => sub {
    my $e = source2pi(
        't/lib/UsesMoose.pm',
        'use Moose;',
    );
    is(
        $e->_module_name(), 'Moose',
        '_module_name'
    );

    ok( $e->_is_ignored, '_is_ignored' );
    is(
        $e->formatted_ppi_statement,
        q{use Moose;},
        'formatted_ppi_statement'
    );
};

subtest 'Import::Into' => sub {
    my $e = source2pi(
        't/lib/MyOwnMoose.pm',
        'use Import::Into;',
    );

    is(
        $e->formatted_ppi_statement,
        q{use Import::Into;},
        'formatted_ppi_statement'
    );

    ok( !$e->has_errors, 'has no errors' );
};

subtest 'Uses MyOwnMoose' => sub {
    my $e = source2pi(
        't/lib/UsesMyOwnMoose.pm',
        'use MyOwnMoose;',
    );

    is(
        $e->formatted_ppi_statement,
        q{use MyOwnMoose;},
        'formatted_ppi_statement'
    );

    ok( !$e->has_errors, 'has no errors' );
};

done_testing();
