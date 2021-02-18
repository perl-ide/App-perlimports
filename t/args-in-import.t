use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper qw( doc );
use Test::More;
use Test::Needs qw( Test2::V0 );

my ($doc) = doc(
    filename  => 'test-data/args-in-import.t',
    selection =>
        q{use Test2::V0 '-no_pragmas' => 1, '!meta', 'diag', 'done_testing', 'is';}
);

is_deeply(
    $doc->original_imports->{'Test2::V0'},
    [ '-no_pragmas', '!meta', 'diag', 'done_testing', 'is' ]
);
done_testing();
