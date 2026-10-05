package Local::MaxA;

use strict;
use warnings;

use Exporter qw( import );
our @EXPORT_OK = qw( max a_only );

sub max    { return 'A' }
sub a_only { return 'a' }

1;
