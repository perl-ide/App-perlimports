use strict;
use warnings;

use Test::More;

use App::perlimports::Document ();
my $doc = App::perlimports::Document->new(
    filename => 'test-data/original-imports.pl' );

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
