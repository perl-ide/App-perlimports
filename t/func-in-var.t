use strict;
use warnings;

use App::perlimports::Document ();
use Test::More;
use Test::Needs qw( Mojo::Util );

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/func-in-var.pl',
    selection => 'use Mojo::Util;',
);

is(
    $doc->tidied_document,
    'use Mojo::Util qw( class_to_path );',
    'func in hash key found'
);

done_testing;
