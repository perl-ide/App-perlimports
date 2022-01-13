use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is )];
use Test::Needs qw( HTTP::Status );

my ($doc) = doc(
    filename  => 'test-data/inner-package.pl',
    selection => 'use HTTP::Status;',
);

is(
    $doc->tidied_document,
    'use HTTP::Status qw( is_redirect is_success );',
    'functions with :: prefix found'
);

done_testing();
