use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper qw( doc );
use Test::More;

my ($doc) = doc(
    filename  => 'test-data/method.pl',
    selection => 'use HTTP::Status;'
);

# Ensure that the ->is_success method call on an HTTP::Response object doesn't
# result in an "is_success" function import for HTTP::Status.

is(
    $doc->tidied_document,
    'use HTTP::Status ();',
    'is_success method not added to function imports'
);

done_testing();
