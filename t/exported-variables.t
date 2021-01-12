use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use Test::More import => [ 'done_testing', 'is', 'is_deeply', 'ok' ];

my $e = App::perlimports->new(
    filename    => 'test-data/exported-variables.pl',
    source_text => 'use ViaExporter qw();',
);

is( $e->_module_name(), 'ViaExporter', '_module_name' );

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
is_deeply( $e->_imports, [ '%foo', '@foo' ], '_imports' );
is(
    $e->formatted_ppi_statement,
    q{use ViaExporter qw( %foo @foo );},
    'formatted_ppi_statement'
);

done_testing();
