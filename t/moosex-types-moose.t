#!/usr/bin/env perl

use strict;
use warnings;

use App::perlimports::Document ();
use Test::More;
use Test::Needs qw( MooseX::Types MooseX::Types::Moose );

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/moosex-types-moose.pl',
    selection => 'use MooseX::Types::Moose qw( ArrayRef );',
);

is(
    $doc->tidied_document,
    'use MooseX::Types::Moose qw( ArrayRef );',
    'imported types found'
);

done_testing;
