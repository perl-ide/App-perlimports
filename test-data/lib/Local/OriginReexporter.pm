package Local::OriginReexporter;
use parent 'Exporter';

use strict;
use warnings;

# Pull a sub in from another module and then re-export it alongside a sub we
# define natively. The export lists alone cannot tell these two apart -- only
# the coderef's true origin package can.
use Local::OriginSource qw( imported_from_source );

our @EXPORT_OK = qw( defined_here imported_from_source );

sub defined_here {
    return 'reexporter';
}

1;
