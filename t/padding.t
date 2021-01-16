use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'subtest' ];

my $source_text = 'use Carp qw( croak verbose );';

my $e = source2pi( 'test-data/carp.pl', $source_text, { pad_imports => 0 } );

is(
    $e->formatted_ppi_statement,
    'use Carp qw(croak verbose);',
    'list is not padded'
);

done_testing();
