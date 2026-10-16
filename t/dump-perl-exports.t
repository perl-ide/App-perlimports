#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => [qw( done_testing subtest )];
use Test::Needs qw( Moose );
use Test::Script 1.29 qw(
    script_compiles
    script_fails
    script_runs
    script_stderr_is
    script_stderr_like
    script_stdout_is
    script_stdout_like
    script_stdout_unlike
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

subtest 'Origin column for re-exported subs' => sub {
    script_runs(
        [
            'script/dump-perl-exports',
            '--libs',   'test-data/lib',
            '--module', 'Local::OriginReexporter'
        ]
    );
    script_stderr_is( q{}, 'no errors' );
    script_stdout_like(
        qr{\|\s+imported_from_source\s+\|\s+Local::OriginSource\s+\|},
        're-exported sub shows its true origin'
    );
    script_stdout_like(
        qr{\|\s+defined_here\s+\|\s+Local::OriginReexporter\s+\|},
        'native sub shows the module itself'
    );
    script_stdout_like(
        qr{\|\s+\$origin_var\s+\|\s+\|},
        'exported variable has a blank origin'
    );
};

subtest 'Origin column for re-exported default exports' => sub {
    script_runs(
        [
            'script/dump-perl-exports',
            '--libs',   'test-data/lib',
            '--module', 'Local::OriginDefaultReexporter'
        ]
    );
    script_stderr_is( q{}, 'no errors' );
    script_stdout_like(
        qr{\|\s+Default Exported Symbols\s+\|\s+Origin\s+\|},
        'default exports table has an Origin column'
    );
    script_stdout_like(
        qr{\|\s+All Exportable Symbols\s+\|\s+Origin\s+\|},
        'exportable symbols table has an Origin column'
    );
    script_stdout_like(
        qr{\|\s+imported_from_source\s+\|\s+Local::OriginSource\s+\|},
        're-exported sub shows its true origin'
    );
};

subtest 'No Origin column without re-exports' => sub {
    script_runs(
        [
            'script/dump-perl-exports',
            '--libs',   'test-data/lib',
            '--module', 'Local::OriginSource'
        ]
    );
    script_stderr_is( q{}, 'no errors' );
    script_stdout_unlike( qr{\|\s+Origin\s+\|}, 'no Origin column' );
};

subtest 'Not Found' => sub {
    script_fails(
        [
            'script/dump-perl-exports', '--module',
            'Local::Does::Not::Exist::Foo'
        ],
        { exit => 1 },
    );
    script_stderr_like(
        qr{\ACould not load Local::Does::Not::Exist::Foo\nCan't locate [^\n]+\n\z},
        'single error when module not found'
    );
    script_stdout_is( q{}, 'no tables printed' );
};

done_testing();
