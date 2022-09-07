#!/usr/bin/env perl

use strict;
use warnings;

use App::perlimports::Config ();
use Path::Tiny               ();
use Test::Differences        qw( eq_or_diff );
use Test::Fatal              qw( exception );
use Test::More import => [qw( done_testing is like ok subtest )];
use TOML::Tiny qw( from_toml );

my $dir  = Path::Tiny->tempdir('testconfigXXXXXXXX');
my $file = $dir->child('perlimports.toml');

ok( App::perlimports::Config->create_config($file), 'create_config' );

my $config = from_toml( $file->slurp );
eq_or_diff( $config->{libs}, [ 'lib', 't/lib' ], 'default libs' );

like(
    exception {
        App::perlimports::Config->create_config($file)
    },
    qr{already exists},
    'file already exists'
);

subtest 'defaults' => sub {

    # Ensure defaults don't throw exceptions
    my $config = App::perlimports::Config->new;
    ok( !$config->cache, 'no cache' );
    eq_or_diff( $config->ignore,         [], 'empty ignore' );
    eq_or_diff( $config->ignore_pattern, [], 'empty ignore_pattern' );
    eq_or_diff( $config->libs,           [], 'empty libs' );
    is( $config->log_filename, q{},     'empty log_filename' );
    is( $config->log_level,    'error', 'log_level is error' );
    eq_or_diff( $config->never_export, [], 'empty never_export' );
    ok( $config->padding,             'padding on' );
    ok( $config->preserve_duplicates, 'preserve_duplicates on' );
    ok( $config->preserve_unused,     'preserve_unused on' );
    ok( $config->tidy_whitespace,     'tidy_whitespace on' );
};

done_testing;
