#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => [qw( done_testing subtest )];
use Test::Needs qw( Moose );
use Test::Script 1.27 qw(
    script_compiles
    script_fails
    script_runs
    script_stderr_is
    script_stderr_like
    script_stdout_like
);

my $script   = 'script/perlimports';
my @filename = ( '--filename', 'test-data/carp.pl' );

script_compiles($script);

subtest 'filename' => sub {
    script_runs( [ $script, @filename ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'implied --filename' => sub {
    script_runs( [ $script, 'test-data/carp.pl' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'help' => sub {
    script_runs( [ $script, '--help' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'libs' => sub {
    script_runs(
        [
            $script,
            '--libs',
            'test-data/lib',
            '--filename',
            'test-data/lib/Local/ViaExporter.pm',
        ]
    );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'log level' => sub {
    script_runs( [ $script, @filename, '--log-level', 'info', ] );
    script_stderr_like( qr{Starting file: test-data/carp.pl}, 'no errors' );
};

subtest 'help' => sub {
    script_runs( [ $script, '--help' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'tidy_whitespace' => sub {
    script_runs(
        [ $script, '--no-tidy-whitespace', 'test-data/preserve-spaces.pl' ] );
    script_stderr_is( q{}, 'no errors' );
    script_stdout_like( qr{use Carp    \(\);}, 'whitespace preserved' );
};

subtest 'verbose help' => sub {
    script_runs( [ $script, '--verbose-help' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'version' => sub {
    script_runs( [ $script, '--version' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'Not Found' => sub {
    script_fails(
        [ $script, '--filename', 'x', ],
        { exit => 1 }
    );
    script_stderr_like(
        qr{x does not appear to be a file},
        'error when module not found'
    );
};

done_testing();
