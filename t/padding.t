use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use Test::More import => [ 'done_testing', 'is', 'subtest' ];

my $source_text = 'use Carp qw( croak verbose );';

my $e = App::perlimports->new(
    filename    => 'test-data/carp.pl',
    pad_imports => 0,
    source_text => $source_text,
);

is(
    $e->formatted_ppi_statement,
    'use Carp qw(croak verbose);',
    'list is not padded'
);

done_testing();
