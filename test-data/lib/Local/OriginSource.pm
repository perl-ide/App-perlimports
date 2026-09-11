package Local::OriginSource;
use parent 'Exporter';

use strict;
use warnings;

our @EXPORT_OK = qw( imported_from_source );

sub imported_from_source {
    return 'source';
}

1;
