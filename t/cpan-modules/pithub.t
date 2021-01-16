use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( Pithub );

my $pi = source2pi(
    'test-data/pithub.pl',
    'use Pithub;',
);

is(
    $pi->formatted_ppi_statement,
    'use Pithub ();',
    'removes implicit export for Moo OO class'
);

done_testing();
