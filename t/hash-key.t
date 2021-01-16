use strict;
use warnings;

use App::perlimports ();
use Test::More;

use lib 't/lib';
use TestHelper qw( file2includes ppi_dump );

my @includes = file2includes('test-data/http-status.pl');

my $e = App::perlimports->new(
    filename => 'test-data/http-status.pl',
    include  => $includes[2],
);

is(
    $e->formatted_ppi_statement,
    q{use HTTP::Status qw( is_info );},
    'does not think hash key is a function'
);

done_testing;
