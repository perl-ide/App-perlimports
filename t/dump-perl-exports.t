#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => [ 'done_testing', 'subtest' ];
use Test::Needs qw( Moose );
use Test::Script 1.27 qw(
    script_compiles
    script_runs
    script_stderr_is
    script_stderr_like
);

script_compiles('script/dump-perl-exports');

subtest 'Moose' => sub {
    script_runs( [ 'script/dump-perl-exports', '--module', 'Moose' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'Moo' => sub {
    script_runs( [ 'script/dump-perl-exports', '--module', 'Moo' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'Local::ViaExporter' => sub {
    script_runs(
        [
            'script/dump-perl-exports',
            '--libs',   'test-data/lib',
            '--module', 'Local::ViaExporter'
        ]
    );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'Not Found' => sub {
    script_runs(
        [
            'script/dump-perl-exports', '--module',
            'Local::Does::Not::Exist::Foo'
        ]
    );
    script_stderr_like( qr{Can't locate}, 'error when module not found' );
};

done_testing();
