use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use Test::More import => [qw( done_testing is is_deeply ok subtest )];

subtest 'with version' => sub {
    my $e = App::perlimports->new(
        filename    => 't/test-data/with-version.pl',
        source_text => 'use LWP::UserAgent 6.49;',
    );

    is_deeply( $e->exports, [], 'no exports' );
    ok( !$e->_is_ignored, '_is_ignored' );
    is_deeply( $e->imports, [], 'imports' );
    is(
        $e->formatted_import_statement,
        q{use LWP::UserAgent 6.49 ();},
        'formatted_import_statement'
    );
};

subtest 'without version' => sub {
    my $e = App::perlimports->new(
        filename    => 't/test-data/with-version.pl',
        source_text => 'use LWP::UserAgent;',
    );

    is_deeply( $e->exports, [], 'no exports' );
    ok( !$e->_is_ignored, '_is_ignored' );
    is_deeply( $e->imports, [], 'imports' );
    is(
        $e->formatted_import_statement,
        q{use LWP::UserAgent ();},
        'formatted_import_statement'
    );
};

subtest 'without incorrect import' => sub {
    my $e = App::perlimports->new(
        filename    => 't/test-data/with-version.pl',
        source_text => 'use LWP::UserAgent qw( new );',
    );

    is_deeply( $e->exports, [], 'no exports' );
    ok( !$e->_is_ignored, '_is_ignored' );
    is_deeply( $e->imports, [], 'imports' );
    is(
        $e->formatted_import_statement,
        q{use LWP::UserAgent ();},
        'formatted_import_statement'
    );
};

done_testing();
