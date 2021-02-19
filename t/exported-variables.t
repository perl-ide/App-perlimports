#!/usr/bin/env perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'is_deeply', 'ok' ];

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/exported-variables.pl',
    selection => 'use Local::ViaExporter qw();',
);

my $pi = App::perlimports::Include->new(
    document => $doc,
    include  => $doc->includes->[0],
);

is_deeply(
    $pi->_explicit_exports,
    {
        'foo'  => 'foo',
        '$foo' => '$foo',
        '@foo' => '@foo',
        '%foo' => '%foo',
    },
    'some _explicit_exports'
);
ok( !$pi->_is_ignored, '_is_ignored' );

is(
    $pi->formatted_ppi_statement,
    q{use Local::ViaExporter qw( $foo %foo @foo );},
    'formatted_ppi_statement'
);

done_testing();
