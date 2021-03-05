use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use TestHelper qw( logger );
use Test::More import => [ 'done_testing', 'is' ];
use Test::Needs qw( HTTP::Status );

my @log;
my $doc = App::perlimports::Document->new(
    filename  => 'test-data/lib/Local/SymbolInExport.pm',
    logger    => logger( \@log ),
    selection => 'use HTTP::Request::Common;',
);

is(
    $doc->tidied_document,
    'use HTTP::Request::Common qw( DELETE GET POST );',
    'imports in exports found'
);

done_testing();
