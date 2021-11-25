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

script_compiles('script/perlimports');

my $script   = 'script/perlimports';
my @filename = ( '--filename', 'test-data/carp.pl' );

subtest 'filename' => sub {
    script_runs( [ $script, @filename ] );
    script_stderr_is( q{}, 'no errors' );
};

#subtest 'implied --filename' => sub {
#script_runs( [ $script, 'Moo' ] );
#script_stderr_is( q{}, 'no errors' );
#};

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
    script_runs( [ 'script/perlimports', '--help' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'verbose help' => sub {
    script_runs( [ 'script/perlimports', '--verbose-help' ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'version' => sub {
    script_runs( [ $script, '--version' ] );
    script_stderr_is( q{}, 'no errors' );
};

#subtest 'Not Found' => sub {
#script_runs(
#[
#'script/perlimports', '--filename', 'x',
#]
#);
#script_stderr_like( qr{Can't locate}, 'error when module not found' );
#};

done_testing();
