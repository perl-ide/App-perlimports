#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( source2pi );
use Test::More import =>
    [ 'done_testing', 'is', 'is_deeply', 'ok', 'subtest' ];

subtest 'with version' => sub {
    my $pi = source2pi(
        'test-data/with-version.pl',
        'use LWP::UserAgent 6.49;',
    );

    ok( !$pi->_is_ignored, '_is_ignored' );
    is(
        $pi->formatted_ppi_statement,
        q{use LWP::UserAgent 6.49 ();},
        'formatted_ppi_statement'
    );

    ok( !$pi->_has_export_inspector, 'export inspection bypassed' );
    is_deeply( $pi->_imports,          [], '_imports' );
    is_deeply( $pi->_explicit_exports, {}, 'no _explicit_exports' );
};

subtest 'without version' => sub {
    my $pi = source2pi(
        'test-data/with-version.pl',
        'use LWP::UserAgent;',
    );

    ok( !$pi->_is_ignored, '_is_ignored' );
    is(
        $pi->formatted_ppi_statement,
        q{use LWP::UserAgent ();},
        'formatted_ppi_statement'
    );

    ok( !$pi->_has_export_inspector, 'export inspection bypassed' );
    is_deeply( $pi->_imports, [], '_imports' );
};

subtest 'without incorrect import' => sub {
    my $pi = source2pi(
        'test-data/with-version.pl',
        'use LWP::UserAgent qw( new );',
    );

    ok( !$pi->_is_ignored, '_is_ignored' );
    is(
        $pi->formatted_ppi_statement,
        q{use LWP::UserAgent ();},
        'formatted_ppi_statement'
    );

    ok( !$pi->_has_export_inspector, 'export inspection bypassed' );
    is_deeply( $pi->_imports,          [], '_imports' );
    is_deeply( $pi->_explicit_exports, {}, 'no _explicit_exports' );
};

done_testing();
