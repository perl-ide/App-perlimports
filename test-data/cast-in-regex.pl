use strict;
use warnings;

use Lingua::EN::Inflect;

my $thing = 'B';
if ( $thing =~ m{ \A b }x ) { ... }
