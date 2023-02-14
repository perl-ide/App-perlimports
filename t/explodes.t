#!perl

use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use PPI::Document ();
use TestHelper    qw( doc );
use Test::More import => [qw( done_testing is ok )];

my ($doc) = doc(
    filename        => 'test-data/explodes.pl',
    preserve_unused => 0,
);

my $expected = <<'EOF';
use strict;
use warnings;

use Local::Explodes qw( foo );

foo();
EOF

is(
    $doc->tidied_document,
    $expected,
    'modules which throw exceptions are ignored'
);

my $raw_include = 'use Local::Explodes qw( foo );';
my $inc         = PPI::Document->new( \$raw_include );
my $found       = $inc->find('PPI::Statement::Include')->[0];

ok( $doc->_is_ignored($found), '_is_ignored' );

done_testing;
