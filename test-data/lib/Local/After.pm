package Local::After;

use Moose;
use List::AllUtils qw( any uniq );

my @foo = uniq { 1..10 };

after run => sub { my @foo = uniq ( 1..9 ) };

sub run { 1; }
1;
