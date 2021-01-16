use strict;
use warnings;

# Ensure that the pragma "use warnings;" does not get mistaken for a use of the
# warnings() function exported via Test::Warnings.

use lib 't/lib';

use App::perlimports ();
use Path::Tiny qw( path );
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

my $filename = 'test-data/pragma.t';

my $content = path($filename)->slurp;
my $doc     = PPI::Document->new( \$content );

my $includes = $doc->find(
    sub {
        $_[1]->isa('PPI::Statement::Include');
    }
) || [];

is( scalar @{$includes}, 4, 'found 4 includes' );

my $e = source2pi(
    $filename,
    undef,
    { include => $includes->[3] },
);

ok( !$e->_is_ignored, 'is not ignored' );
is(
    $e->formatted_ppi_statement,
    q{use Test::Warnings ();},
    'formatted_ppi_statement'
);

done_testing;
