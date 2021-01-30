use strict;
use warnings;

use App::perlimports::Document ();
use Test::More import => [qw( done_testing is_deeply )];

my $doc = App::perlimports::Document->new(
    filename => 'test-data/interpolation.pl' );

is_deeply( $doc->vars, { '$code' => 1, encode => 1 }, 'vars' );

done_testing();
