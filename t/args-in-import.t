#!perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is_deeply )];
use Test::Needs qw( Test2::V0 );

my ($doc) = doc(
    filename  => 'test-data/args-in-import.t',
    selection =>
        q{use Test2::V0 '-no_pragmas' => 1, '!meta', 'diag', 'done_testing', 'is';}
);

is_deeply(
    $doc->original_imports->{'Test2::V0'},
    [ '-no_pragmas', '!meta', 'diag', 'done_testing', 'is' ],
    'original_imports'
);
done_testing();
