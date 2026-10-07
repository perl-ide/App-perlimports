package Local::OriginMissingSub;
use parent 'Exporter';

use strict;
use warnings;

# not_defined has no sub behind it.
our @EXPORT_OK = qw( defined_here not_defined );

sub defined_here {
    return 'missing sub';
}

1;
