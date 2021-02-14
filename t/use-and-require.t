use strict;
use warnings;

use App::perlimports::Document ();
use Test::More;

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/use-and-require.pl',
    selection => 'use Fcntl;',
);

is(
    $doc->tidied_document,
    'use Fcntl qw( O_RDONLY );',
    'require not used to find existing imports'
);

done_testing;
