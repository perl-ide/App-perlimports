use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( Mojo::Util );

my ($doc) = doc(
    filename  => 'test-data/func-in-var.pl',
    selection => 'use Mojo::Util;',
);

is(
    $doc->tidied_document,
    'use Mojo::Util qw( class_to_path );',
    'func in hash key found'
);

done_testing;
