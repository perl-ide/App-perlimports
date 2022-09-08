#!perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is ok )];

my ($doc) = doc(
    filename => 'test-data/lib/Local/UsesTypesStandard.pm',
);

my $expected = <<'EOF';
package Local::UsesTypesStandard;

use Types::Standard;

1;
EOF

my $includes = $doc->ppi_document->find('PPI::Statement::Include');
is( $includes->[0]->module, 'Types::Standard', 'module name' );
ok( $doc->_is_ignored( $includes->[0] ), 'is_ignored flag set' );
is( $doc->tidied_document, $expected, 'Types::Standard is ignored' );

done_testing();
