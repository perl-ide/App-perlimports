package Local::OriginSource;
use parent 'Exporter';

use strict;
use warnings;

our @EXPORT_OK = qw( also_from_source imported_from_source );

sub also_from_source {
    return 'also source';
}

sub imported_from_source {
    return 'source';
}

1;
