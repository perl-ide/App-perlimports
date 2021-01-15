use strict;
use warnings;

use App::perlimports ();
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( Pithub );

my $pi = App::perlimports->new(
    filename    => 'test-data/pithub.pl',
    source_text => 'use Pithub;',
);

is(
    $pi->formatted_ppi_statement,
    'use Pithub ();',
    'removes implicit export for Moo OO class'
);

done_testing();
