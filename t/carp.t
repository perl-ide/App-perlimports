use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use Test::More import => [ 'done_testing', 'is', 'is_deeply', 'subtest' ];

subtest 'verbose' => sub {
    my $source_text = 'use Carp qw( croak verbose );';

    my $e = App::perlimports->new(
        filename    => 'test-data/carp.pl',
        source_text => $source_text,
    );

    is(
        $e->formatted_ppi_statement,
        $source_text,
        'verbose is preserved'
    );

    is_deeply(
        $e->_original_imports,
        [ 'croak', 'verbose' ],
        'original imports'
    );
};

subtest 'verbose' => sub {
    my $source_text = 'use Carp qw( croak );';

    my $e = App::perlimports->new(
        filename    => 'test-data/carp.pl',
        source_text => $source_text,
    );

    is(
        $e->formatted_ppi_statement,
        $source_text,
        'verbose is not inserted'
    );

    is_deeply(
        $e->_original_imports,
        ['croak'],
        'original imports'
    );
};

done_testing();
