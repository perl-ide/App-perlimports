#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( file2includes source2pi );
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( HTTP::Status );

my @includes = file2includes('test-data/http-status.pl');

my $e = source2pi(
    'test-data/http-status.pl', undef,
    { include => $includes[2] }
);

is(
    $e->formatted_ppi_statement,
    q{use HTTP::Status qw( is_info );},
    'does not think hash key is a function'
);

done_testing;
