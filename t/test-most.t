use strict;
use warnings;

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

my %modules = (
    'Test::More' => 'test-data/test-more.t',
    'Test::Most' => 'test-data/test-most.t'
);

for my $module ( keys %modules ) {
    subtest $module => sub {
        my $doc = App::perlimports::Document->new(
            filename  => $modules{$module},
            selection => "use $module;",
        );

        is(
            $doc->tidied_document,
            "use $module import => [ qw( done_testing ) ];",
            'tidied document'
        );
    };
}

done_testing();
