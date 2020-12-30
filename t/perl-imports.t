use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use Test::More import => [qw( diag done_testing is is_deeply ok subtest )];

subtest 'Getopt::Long' => sub {
    my $e = App::perlimports->new(
        filename    => 't/test-data/foo.pl',
        source_text => 'use Getopt::Long;',
    );
    is(
        $e->_module_name(), 'Getopt::Long',
        '_module_name'
    );

    ok( @{ $e->_exports },             'Found some _exports' );
    ok( !$e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->_imports, ['GetOptions'], '_imports' );
    ok( !$e->_uses_sub_exporter, '_uses_sub_exporter' );
    is(
        $e->formatted_ppi_statement, 'use Getopt::Long qw( GetOptions );',
        'formatted_ppi_statement'
    );
};

subtest 'Test::More' => sub {
    my $e = App::perlimports->new(
        filename    => 't/test-data/foo.t',
        source_text => 'use Test::More;',
    );
    is(
        $e->_module_name(), 'Test::More',
        '_module_name'
    );

    ok( @{ $e->_exports },            'Found some _exports' );
    ok( $e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->_imports, [ 'done_testing', 'ok' ], '_imports' );
    ok( !$e->_uses_sub_exporter, '_uses_sub_exporter' );
    is(
        $e->formatted_ppi_statement,
        'use Test::More import => [ qw( done_testing ok ) ];',
        'formatted_ppi_statement'
    );
};

subtest 'pragma' => sub {
    my $e = App::perlimports->new(
        filename    => 't/test-data/foo.t',
        source_text => 'use strict;',
    );
    is(
        $e->_module_name(), 'strict',
        '_module_name'
    );

    ok( !@{ $e->_exports },            'Found some _exports' );
    ok( !$e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->_imports, [], '_imports' );
    ok( !$e->_uses_sub_exporter, '_uses_sub_exporter' );
    is(
        $e->formatted_ppi_statement,
        'use strict;',
        'formatted_ppi_statement'
    );
};

subtest 'ViaExporter' => sub {
    my $e = App::perlimports->new(
        filename    => 't/test-data/via-exporter.pl',
        source_text => 'use ViaExporter qw( foo $foo @foo %foo );',
    );
    is(
        $e->_module_name(), 'ViaExporter',
        '_module_name'
    );

    is_deeply(
        $e->_exports, [qw( foo $foo @foo %foo )],
        'Found some _exports'
    );
    ok( !$e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->_imports, [qw( $foo %foo @foo foo )], '_imports' );
    ok( !$e->_uses_sub_exporter, '_uses_sub_exporter' );
    is(
        $e->formatted_ppi_statement,
        'use ViaExporter qw( $foo %foo @foo foo );',
        'formatted_ppi_statement'
    );
};
done_testing();
