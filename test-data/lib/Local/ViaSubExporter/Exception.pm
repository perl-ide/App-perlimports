package Local::ViaSubExporter::Exception;

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [
        'bar',
        'foo',
    ]
};

sub bar { }

1;
