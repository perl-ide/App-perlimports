use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use Test::More import => [qw( diag done_testing is is_deeply ok )];

my $e = App::perlimports->new(
    filename    => 't/test-data/with-version.pl',
    source_text => 'use Getopt::Long 2.40 qw();',
);
is(
    $e->module_name(), 'Getopt::Long',
    'module_name'
);

ok( @{ $e->_exports }, 'some _exports' );
ok( !$e->_is_ignored, '_is_ignored' );
is_deeply( $e->_imports, ['GetOptions'], '_imports' );
is(
    $e->formatted_import_statement,
    q{use Getopt::Long 2.40 qw( GetOptions );},
    'formatted_import_statement'
);

done_testing();
