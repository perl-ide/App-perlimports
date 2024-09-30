use strict;
use warnings;

use Tie::SubstrHash ();

tie my %hash, 'Tie::SubstrHash', 1, 1, 1;
