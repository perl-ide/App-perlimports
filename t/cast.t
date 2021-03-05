use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper qw( doc );
use Test::More;
use Test::Needs qw( Mojo::Util );

my ( $doc, $log ) = doc(
    filename  => 'test-data/cast.pl',
    selection => 'use Mojo::Util;',
);

is(
    $doc->tidied_document,
    'use Mojo::Util qw( split_header );',
    'interpolated func found'
);

done_testing;
