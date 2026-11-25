package Local::OriginReexporter;
use parent 'Exporter';

use strict;
use warnings;

# Re-exports subs from Local::OriginSource alongside one defined here.
use Local::OriginSource qw( also_from_source imported_from_source );

our $origin_var = 1;

# defined_here is listed twice and &also_from_source has a sigil.
our @EXPORT    = qw( defined_here );
our @EXPORT_OK = qw(
    $origin_var
    &also_from_source
    defined_here
    imported_from_source
);

sub defined_here {
    return 'reexporter';
}

1;
