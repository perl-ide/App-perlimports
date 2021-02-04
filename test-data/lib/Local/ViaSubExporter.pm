package Local::ViaSubExporter;

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [
        'bar',
        'foo',
    ]
};

sub bar { }
sub foo { }

1;
