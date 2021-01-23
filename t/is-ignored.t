use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

my $doc = App::perlimports::Document->new(
    filename => 't/lib/UsesTypesStandard.pm',
);

my $expected = <<EOF;
package UsesTypesStandard;

use Types::Standard;

1;
EOF

ok( $doc->_is_ignored('Types::Standard'), 'is_ignored flag set' );
is( $doc->tidied_document, $expected, 'Types::Standard is ignored' );

done_testing();
