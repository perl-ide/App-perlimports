#!/usr/bin/env perl

use strict;
use warnings;

use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( done_testing )];
use Test::Needs qw( Mojo::URL );

use lib 't/lib';
use TestHelper qw( doc logger );

my $log = [];

my $logger = logger( $log, 'warning' );
my ($doc) = doc(
    filename => 'test-data/mojo-url.pl',
    logger   => $logger,
);
$doc->tidied_document;

eq_or_diff( $log, [], 'no Mojo warnings' );

done_testing();
