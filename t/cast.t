use strict;
use warnings;

use App::perlimports::Document ();
use Test::More;
use Test::Needs qw( Mojo::Util );

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/cast.pl',
    selection => 'use Mojo::Util;',
);

is(
    $doc->tidied_document,
    'use Mojo::Util qw( split_header );',
    'interpolated func found'
);

done_testing;
