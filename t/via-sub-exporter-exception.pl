#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use Path::Tiny qw( path );
use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];

my $filename = 'test-data/via-sub-exporter-exception.pl';
my ($doc) = doc(
    filename        => $filename,
    preserve_unused => 0,
);

is( $doc->tidied_document, path($filename)->slurp, 'doc has not changed' );

done_testing();
