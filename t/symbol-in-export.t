use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use TestHelper qw( doc logger );
use Test::More import => [ 'done_testing', 'is', 'is_deeply' ];
use Test::Needs qw( HTTP::Status );

my ($doc) = doc(
    filename  => 'test-data/lib/Local/SymbolInExport.pm',
    selection => 'use HTTP::Request::Common;',
);

is(
    $doc->tidied_document,
    'use HTTP::Request::Common qw( DELETE GET POST );',
    'imports in exports found'
);

done_testing();
