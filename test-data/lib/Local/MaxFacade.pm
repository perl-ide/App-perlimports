package Local::MaxFacade;

use strict;
use warnings;

use Exporter    qw( import );
use Local::MaxA qw( max );
our @EXPORT_OK = qw( max facade_only );

sub facade_only { return 'f' }

1;
