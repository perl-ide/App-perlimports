#!/usr/bin/env perl

use strict;
use warnings;

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is', 'ok' ];

my $doc = App::perlimports::Document->new(
    filename => 'test-data/lib/Local/UsesTypesStandard.pm',
);

my $expected = <<EOF;
package Local::UsesTypesStandard;

use Types::Standard;

1;
EOF

my $includes = $doc->ppi_document->find('PPI::Statement::Include');
is( $includes->[0]->module, 'Types::Standard' );
ok( $doc->_is_ignored( $includes->[0] ), 'is_ignored flag set' );
is( $doc->tidied_document, $expected, 'Types::Standard is ignored' );

done_testing();
