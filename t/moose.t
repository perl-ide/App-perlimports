use strict;
use warnings;

use App::perlimports ();
use Test::More import =>
    [ 'diag', 'done_testing', 'is', 'is_deeply', 'ok', 'subtest' ];

use lib 't/lib';

subtest 'Moose' => sub {
    my $e = App::perlimports->new(
        filename    => 't/lib/UsesMoose.pm',
        source_text => 'use Moose;',
    );
    is(
        $e->_module_name(), 'Moose',
        '_module_name'
    );

    is_deeply( $e->_combined_exports, {}, 'No _combined_exports' );
    ok( $e->_is_ignored, '_is_ignored' );
    is_deeply( $e->_imports, [], 'No _imports' );
    is(
        $e->formatted_ppi_statement,
        q{use Moose;},
        'formatted_ppi_statement'
    );
};

subtest 'Import::Into' => sub {
    my $e = App::perlimports->new(
        filename    => 't/lib/MyOwnMoose.pm',
        source_text => 'use Import::Into;',
    );

    is(
        $e->formatted_ppi_statement,
        q{use Import::Into;},
        'formatted_ppi_statement'
    );

    ok( !$e->has_errors, 'has no errors' );
};

subtest 'Uses MyOwnMoose' => sub {
    my $e = App::perlimports->new(
        filename    => 't/lib/UsesMyOwnMoose.pm',
        source_text => 'use MyOwnMoose;',
    );

    is(
        $e->formatted_ppi_statement,
        q{use MyOwnMoose;},
        'formatted_ppi_statement'
    );

    ok( !$e->has_errors, 'has no errors' );
    use DDP;
    diag np $e->errors;
};

done_testing();
