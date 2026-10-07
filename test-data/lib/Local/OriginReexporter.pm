package Local::OriginReexporter;
use parent 'Exporter';

use strict;
use warnings;

# Re-exports a sub from Local::OriginSource alongside one defined here.
use Local::OriginSource qw( imported_from_source );

our $origin_var = 1;

our @EXPORT_OK = qw( $origin_var defined_here imported_from_source );

sub defined_here {
    return 'reexporter';
}

1;
