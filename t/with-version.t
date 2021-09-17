use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'is_deeply', 'ok' ];
use Test::Needs qw( Cpanel::JSON::XS );

my $e = source2pi(
    'test-data/with-version.pl',
    'use Getopt::Long 2.40 qw();',
);
is(
    $e->module_name(), 'Getopt::Long',
    'module_name'
);

ok( !$e->_is_ignored, '_is_ignored' );
is_deeply( $e->_imports, ['GetOptions'], '_imports' );
is(
    $e->formatted_ppi_statement,
    q{use Getopt::Long 2.40 qw( GetOptions );},
    'formatted_ppi_statement'
);

done_testing();
