package Local::ReExportViaSubExporter;

use strict;
use warnings;

use Carp;

use Sub::Exporter -setup => {
    exports => [
        'croak',
        'other_func',
    ]
};

sub other_func { }

1;
