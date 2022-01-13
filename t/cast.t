use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( Mojo::Util );

my ($doc) = doc(
    filename  => 'test-data/cast.pl',
    selection => 'use Mojo::Util;',
);

is(
    $doc->tidied_document,
    'use Mojo::Util qw( split_header );',
    'interpolated func found'
);

done_testing;
