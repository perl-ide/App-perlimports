#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use Test::More import => [ 'done_testing', 'ok' ];
use Test::Needs qw( Import::Into );
use TestHelper qw( source2pi );

my $source_text = 'use Local::UsesImportInto;';
my $e
    = source2pi( 'test-data/lib/Local/UsesUsesImportInto.pm', $source_text );

ok( $e->_is_ignored, 'is ignored' );
ok( !$e->has_errors, 'has no errors' );

done_testing();
