#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'is_deeply', 'ok' ];

my $e = source2pi(
    'test-data/find-bin.pl',
    'use FindBin qw( $Bin );',
);
is(
    $e->module_name(), 'FindBin',
    'module_name'
);

ok( !$e->_is_ignored, 'no longer ignored' );
is_deeply( $e->_imports, [qw($Bin)], 'found import' );
is(
    $e->formatted_ppi_statement,
    q{use FindBin qw( $Bin );},
    'formatted_ppi_statement'
);

done_testing();
