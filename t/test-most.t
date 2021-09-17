use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper qw( logger );
use Test::More import => [ 'done_testing', 'is', 'subtest' ];
use Test::Needs qw( Test::Most );

my %modules = (
    'Test::More' => 'test-data/test-more.t',
    'Test::Most' => 'test-data/test-most.t'
);

for my $module ( keys %modules ) {
    subtest $module => sub {
        my @log;
        my $doc = App::perlimports::Document->new(
            filename  => $modules{$module},
            logger    => logger( \@log ),
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
