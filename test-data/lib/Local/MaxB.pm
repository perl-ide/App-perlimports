package Local::MaxB;

use strict;
use warnings;

use Exporter qw( import );
our @EXPORT_OK = qw( max b_only );

sub max    { return 'B' }
sub b_only { return 'b' }

1;
