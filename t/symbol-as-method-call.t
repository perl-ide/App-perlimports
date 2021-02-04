use strict;
use warnings;

use App::perlimports::Document ();
use Test::More;
use Test::Needs qw( HTML::TableExtract Object::Tap );

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/symbol-as-method-call.pl',
    selection => 'use Object::Tap;',
);

is(
    $doc->tidied_document,
    'use Object::Tap qw( $_tap );',
    'symbol in method call found'
);

done_testing;
