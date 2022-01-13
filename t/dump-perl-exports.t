#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => [qw( done_testing subtest )];
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

subtest 'implied --module' => sub {
    script_runs( [ 'script/dump-perl-exports', 'Moo' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'help' => sub {
    script_runs( [ 'script/dump-perl-exports', '--help' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'libs' => sub {
    script_runs(
        [
            'script/dump-perl-exports',
            '--libs',
            'test-data/lib',
            'Local::ViaExporter'
        ]
    );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'log level' => sub {
    script_runs(
        [ 'script/dump-perl-exports', '--log-level', 'info', 'Moo' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'verbose help' => sub {
    script_runs( [ 'script/dump-perl-exports', '--verbose-help' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'version' => sub {
    script_runs( [ 'script/dump-perl-exports', '--version' ] );
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
