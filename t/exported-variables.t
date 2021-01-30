use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'is_deeply', 'ok' ];

my $e = source2pi(
    'test-data/exported-variables.pl',
    'use ViaExporter qw();',
);

is_deeply(
    $e->_combined_exports,
    {
        'foo'  => 'foo',
        '$foo' => '$foo',
        '@foo' => '@foo',
        '%foo' => '%foo',
    },
    'some _combined_exports'
);
ok( !$e->_is_ignored, '_is_ignored' );
is(
    $e->formatted_ppi_statement,
    q{use ViaExporter qw( $foo %foo @foo );},
    'formatted_ppi_statement'
);

done_testing();
