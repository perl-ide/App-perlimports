#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( MooseX::Types MooseX::Types::Moose );

my ($doc) = doc(
    filename  => 'test-data/moosex-types-moose.pl',
    selection => 'use MooseX::Types::Moose qw( ArrayRef );',
);

is(
    $doc->tidied_document,
    'use MooseX::Types::Moose qw( ArrayRef );',
    'imported types found'
);

done_testing;
