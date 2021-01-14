use strict;
use warnings;

use App::perlimports ();
use Test::More import =>
    [ 'done_testing', 'is', 'is_deeply', 'ok', 'subtest' ];

subtest 'with version' => sub {
    my $e = App::perlimports->new(
        filename    => 'test-data/with-version.pl',
        source_text => 'use LWP::UserAgent 6.49;',
    );

    ok( !$e->_is_ignored, '_is_ignored' );
    is(
        $e->formatted_ppi_statement,
        q{use LWP::UserAgent 6.49 ();},
        'formatted_ppi_statement'
    );

    ok( !$e->_has_export_inspector, 'export inspection bypassed' );
    is_deeply( $e->_imports,          [], '_imports' );
    is_deeply( $e->_combined_exports, {}, 'no _combined_exports' );
};

subtest 'without version' => sub {
    my $e = App::perlimports->new(
        filename    => 'test-data/with-version.pl',
        source_text => 'use LWP::UserAgent;',
    );

    ok( !$e->_is_ignored, '_is_ignored' );
    is(
        $e->formatted_ppi_statement,
        q{use LWP::UserAgent ();},
        'formatted_ppi_statement'
    );

    ok( !$e->_has_export_inspector, 'export inspection bypassed' );
    is_deeply( $e->_imports, [], '_imports' );
};

subtest 'without incorrect import' => sub {
    my $e = App::perlimports->new(
        filename    => 'test-data/with-version.pl',
        source_text => 'use LWP::UserAgent qw( new );',
    );

    ok( !$e->_is_ignored, '_is_ignored' );
    is(
        $e->formatted_ppi_statement,
        q{use LWP::UserAgent ();},
        'formatted_ppi_statement'
    );

    ok( !$e->_has_export_inspector, 'export inspection bypassed' );
    is_deeply( $e->_imports,          [], '_imports' );
    is_deeply( $e->_combined_exports, {}, 'no _combined_exports' );
};

done_testing();
