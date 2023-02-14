#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing is_deeply subtest )];

subtest 'verbose' => sub {
    my ($doc) = doc( filename => 'test-data/carp.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Carp qw( croak verbose );

croak('oof');
EOF
    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'verbose is preserved'
    );
};

subtest 'no verbose' => sub {
    my ($doc) = doc( filename => 'test-data/carp-without-verbose.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Carp qw( croak );

croak('oof');
EOF

    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'verbose is not inserted'
    );
};

subtest 'no imports' => sub {
    my ($doc) = doc( filename => 'test-data/carp-with-no-imports.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Carp qw( croak );

croak('oof');
EOF

    is_deeply(
        $doc->original_imports->{Carp},
        undef,
        'original imports'
    );

    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'verbose is not inserted'
    );

    is_deeply(
        $doc->original_imports,
        { Carp => ['croak'] },
        'original imports updated'
    );
};

done_testing();
