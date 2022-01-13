use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper qw( logger );
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( HTML::TableExtract Object::Tap );

my @errors;
my $logger = logger( \@errors );

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/symbol-as-method-call.pl',
    logger    => $logger,
    selection => 'use Object::Tap;',
);

is(
    $doc->tidied_document,
    'use Object::Tap qw( $_tap );',
    'symbol in method call found'
);

done_testing;
