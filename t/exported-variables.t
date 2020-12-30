use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use Test::More import => [qw( diag done_testing is is_deeply ok )];

my $e = App::perlimports->new(
    filename    => 't/test-data/exported-variables.pl',
    source_text => 'use ViaExporter qw();',
);

is( $e->module_name(), 'ViaExporter', 'module_name' );

is_deeply(
    $e->_exports,
    [
        'foo',
        '$foo',
        '@foo',
        '%foo',
    ],
    'some _exports'
);
ok( !$e->_is_ignored, '_is_ignored' );
is_deeply( $e->imports, [ '%foo', '@foo' ], 'imports' );
is(
    $e->formatted_import_statement,
    q{use ViaExporter qw( %foo @foo );},
    'formatted_import_statement'
);

done_testing();
