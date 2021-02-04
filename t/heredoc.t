#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::More import => [ 'done_testing', 'is' ];
use TestHelper qw( source2pi );

my $source_text = 'use Perl::Critic::Utils;';
my $e           = source2pi( 'test-data/heredoc.pl', $source_text );

is(
    $e->formatted_ppi_statement,
    'use Perl::Critic::Utils qw( $QUOTE );',
    'var in heredoc found'
);

done_testing();
