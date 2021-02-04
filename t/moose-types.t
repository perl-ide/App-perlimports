#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is' ];
use Test::Needs qw( MooseX::Types::Path::Class );

my $e = source2pi(
    'test-data/messy-imports.pl',
    'use Local::MooseTypeLibrary;',
);

my $expected = <<'EOF';
use Local::MooseTypeLibrary qw(
    ArrayRef
    Bool
    CodeRef
    FileHandle
    HashRef
    Maybe
    Object
    RegexpRef
    Str
);
EOF
chomp $expected;

is(
    $e->formatted_ppi_statement,
    $expected,
    'formatted_ppi_statement'
);

done_testing();
