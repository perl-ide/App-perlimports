#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( file2includes source2pi );
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( HTTP::Status );

my @includes = file2includes('test-data/hash-unquoted-key.pl');

my $e = source2pi(
    'test-data/hash-unquoted-key.pl', undef,
    { include => $includes[2] }
);

is(
    $e->formatted_ppi_statement,
    'use HTTP::Status ();',
    'recognizes is_info as a word representing a string'
);

done_testing;
