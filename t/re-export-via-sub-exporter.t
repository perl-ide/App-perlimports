use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper qw( doc );
use Test::More import => ['done_testing'];

my ($doc) = doc(
    filename        => 'test-data/lib/Local/ReExportViaSubExporter.pm',
    preserve_unused => 0,
);

my $expected = <<'EOF';
package Local::ReExportViaSubExporter;

use strict;
use warnings;

use Carp qw( croak );

use Sub::Exporter -setup => {
    exports => [
        'croak',
        'other_func',
    ]
};

sub other_func { }

1;
EOF

eq_or_diff( $doc->tidied_document, $expected, 'croak detected' );

done_testing();
