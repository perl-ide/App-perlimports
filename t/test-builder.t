use strict;
use warnings;

use lib 't/lib';

use TestHelper  qw( inspector );
use Test::Needs qw( Test::HTML::Lint );
use Test::More import => [qw( done_testing ok )];

my ($ei) = inspector('Test::HTML::Lint');

ok( $ei->isa_test_builder, 'isa_test_builder' );

done_testing();
