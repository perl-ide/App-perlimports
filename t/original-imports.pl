use strict;
use warnings;

use Test::More;

use App::perlimports::Document ();
my $doc = App::perlimports::Document->new(
    filename => 'test-data/original-imports.pl' );

# use Carp; => undef
# use Data::Dumper qw( Dumper ); => ['Dumper']
# use POSIX (); => []

is_deeply(
    $doc->original_imports,
    {
        Carp           => undef,
        'Data::Dumper' => ['Dumper'],
        POSIX          => [],
    },
    'original imports'
);
done_testing();
