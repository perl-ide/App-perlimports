package Local::OriginDefaultReexporter;
use parent 'Exporter';

use strict;
use warnings;

# Re-exports a sub by default.
use Local::OriginSource qw( imported_from_source );

our @EXPORT = qw( defined_here imported_from_source );

sub defined_here {
    return 'default reexporter';
}

1;
