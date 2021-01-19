use strict;
use warnings;

use lib 't/lib';

use Test::More import => [ 'done_testing', 'is' ];
use Test::Needs qw( File::Spec::Functions );
use TestHelper qw( source2pi );

my $source_text = 'use File::Spec::Functions;';
my $e           = source2pi( 'test-data/func-in-use.pl', $source_text );

is(
    $e->formatted_ppi_statement,
    'use File::Spec::Functions qw( catdir );',
    'func in use statement is detected'
);

done_testing();
