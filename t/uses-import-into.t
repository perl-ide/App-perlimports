use strict;
use warnings;

use lib 't/lib';

use Test::More import => [ 'done_testing', 'ok' ];
use TestHelper qw( source2pi );

my $source_text = 'use UsesImportInto;';
my $e           = source2pi( 't/lib/UsesUsesImportInto.pm', $source_text );

ok( $e->_is_ignored, 'is ignored' );
ok( !$e->has_errors, 'has no errors' );

done_testing();
