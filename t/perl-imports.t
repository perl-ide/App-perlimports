#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use TestHelper qw( doc source2pi );
use Test::More import =>
    [ 'done_testing', 'is', 'is_deeply', 'ok', 'subtest' ];

subtest 'Getopt::Long' => sub {
    my $e = source2pi(
        'test-data/foo.pl',
        'use Getopt::Long;',
    );
    is(
        $e->_module_name(), 'Getopt::Long',
        '_module_name'
    );

    ok( $e->_has_explicit_exports,     'Found some _explicit_exports' );
    ok( !$e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->_imports, ['GetOptions'], '_imports' );
    is(
        $e->formatted_ppi_statement,
        'use Getopt::Long qw( GetOptions );',
        'formatted_ppi_statement'
    );
};

subtest 'Test::More' => sub {
    my $e = source2pi(
        'test-data/foo.t',
        'use Test::More;',
    );
    is(
        $e->_module_name(), 'Test::More',
        '_module_name'
    );

    ok( $e->_has_explicit_exports,    'Found some _explicit_exports' );
    ok( $e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->_imports, [qw( done_testing ok)], '_imports' );
    is(
        $e->formatted_ppi_statement,
        q{use Test::More import => [ qw( done_testing ok ) ];},
        'formatted_ppi_statement'
    );
};

subtest 'pragma' => sub {
    my ($doc) = doc(
        filename  => 'test-data/foo.t',
        selection => 'use strict;',
    );

    is(
        $doc->tidied_document,
        'use strict;',
        'formatted_ppi_statement'
    );
};

subtest 'ViaExporter' => sub {
    my $e = source2pi(
        'test-data/via-exporter.pl',
        'use Local::ViaExporter qw( foo $foo @foo %foo );',
    );
    is(
        $e->_module_name(), 'Local::ViaExporter',
        '_module_name'
    );

    is_deeply(
        $e->_explicit_exports,
        {
            '$foo' => '$foo',
            '%foo' => '%foo',
            '@foo' => '@foo',
            'foo'  => 'foo',
        },
        'Found some _explicit_exports'
    );
    ok( !$e->_isa_test_builder_module, 'isa_test_builder_module' );
    is_deeply( $e->_imports, [qw( $foo %foo @foo foo )], '_imports' );
    is(
        $e->formatted_ppi_statement,
        'use Local::ViaExporter qw( $foo %foo @foo foo );',
        'formatted_ppi_statement'
    );
};
done_testing();
