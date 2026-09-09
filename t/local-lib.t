#!perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is ok )];

# local::lib manipulates @INC as a side effect of being used. It exports
# nothing we'd want to manage, so perlimports must never rewrite or remove
# "use local::lib". See GH #117. It's in the default ignore list, so this
# holds whether or not local::lib is installed.

my ($doc) = doc(
    filename => 'test-data/local-lib.pl',
);

my $expected = <<'EOF';
use strict;
use warnings;

use local::lib;

1;
EOF

my $includes = $doc->ppi_document->find('PPI::Statement::Include');
is( $includes->[2]->module, 'local::lib', 'module name' );
ok( $doc->_is_ignored( $includes->[2] ), 'local::lib flagged as ignored' );
is( $doc->tidied_document, $expected, 'use local::lib is left untouched' );

done_testing();
