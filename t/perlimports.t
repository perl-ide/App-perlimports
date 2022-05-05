#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();
use Test::Differences qw( eq_or_diff );
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
use TOML::Tiny qw( from_toml );

my $script   = 'script/perlimports';
my @filename = ( '--filename', 'test-data/carp.pl' );

script_compiles($script);

sub tmp_perl_file {
    my $file = Path::Tiny->tempfile('testXXXX');
    $file->spew('use strict;use warnings;');
    return $file;
}

subtest 'provide config file' => sub {
    my $file = tmp_perl_file();
    script_runs(
        [ $script, '--config-file', 'test-data/perlimports.toml', "$file" ] );
    script_stderr_is( q{}, 'no errors' );
};

subtest 'config file not found' => sub {
    my $file = tmp_perl_file();
    script_fails(
        [ $script, '--config-file', 'test-data/Xperlimports.toml', "$file" ],
        { exit => 1 }
    );

    script_stderr_like( qr{Xperlimports.toml not found}, 'not found error' );
};

subtest 'create config file' => sub {
    my $dir  = Path::Tiny->tempdir('testconfigXXXXXXXX');
    my $file = $dir->child('perlimports.toml');

    script_runs( [ $script, '--create-config-file', "$file" ] );
    script_stderr_is( q{}, 'no errors' );

    my $config = from_toml( $file->slurp );
    eq_or_diff( $config->{libs}, [ 'lib', 't/lib' ], 'default libs' );
    script_fails(
        [ $script, '--create-config-file', "$file" ],
        { exit => 1 },
    );
    script_stderr_like( qr{already exists}, 'error clobbering file' );
};

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
        [
            $script, '--no-config-file', '--no-tidy-whitespace',
            'test-data/preserve-spaces.pl'
        ]
    );
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
