use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper qw( doc );
use Test::More;
use Test::Needs qw( File::chdir );

my ($doc) = doc(
    filename  => 'test-data/typeglob.pl',
    selection => 'use File::chdir;',
);

is(
    $doc->tidied_document,
    'use File::chdir qw( *CWD );',
    'translates $CWD to *CWD in import'
);

done_testing;
