use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper                 qw( logger );
use Test::More import => [qw( done_testing is )];

my @log;

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/use-and-require.pl',
    logger    => logger( \@log ),
    selection => 'use Fcntl;',
);

is(
    $doc->tidied_document,
    'use Fcntl qw( O_RDONLY );',
    'require not used to find existing imports'
);

done_testing;
