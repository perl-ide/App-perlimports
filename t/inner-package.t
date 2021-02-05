use strict;
use warnings;

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is' ];
use Test::Needs qw( HTTP::Status );

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/inner-package.pl',
    selection => 'use HTTP::Status;',
);

is(
    $doc->tidied_document,
    'use HTTP::Status qw( is_redirect is_success );',
    'functions with :: prefix found'
);

done_testing();
