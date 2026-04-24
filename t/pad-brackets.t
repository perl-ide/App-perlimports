#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use TestHelper qw( doc source2pi );
use Test::More import => [qw( done_testing is subtest )];

subtest 'default (tight brackets)' => sub {
    my $e = source2pi(
        'test-data/foo.t',
        'use Test::More;',
    );
    is(
        $e->formatted_ppi_statement,
        'use Test::More import => [qw( done_testing ok )];',
        'default uses tight brackets'
    );
};

subtest 'no padding' => sub {
    my ($doc) = doc(
        filename     => 'test-data/foo.t',
        pad_brackets => 0,
    );
    is(
        $doc->tidied_document,
        <<'EOF', 'pad_brackets=0 produces tight brackets' );
use strict;
use warnings;

use Test::More import => [qw( done_testing ok )];

ok(1);
done_testing;
EOF
};

subtest 'padded brackets explicitly' => sub {
    my ($doc) = doc(
        filename     => 'test-data/foo.t',
        pad_brackets => 1,
    );
    is(
        $doc->tidied_document,
        <<'EOF', 'pad_brackets=1 produces padded brackets' );
use strict;
use warnings;

use Test::More import => [ qw( done_testing ok ) ];

ok(1);
done_testing;
EOF
};

subtest 'path 1 tight brackets (test builder with args)' => sub {
    my $e = source2pi(
        'test-data/foo.t',
        'use Test::More import => [qw( ok )];',
        { pad_brackets => 0 },
    );
    is(
        $e->formatted_ppi_statement,
        'use Test::More import => [qw( done_testing ok )];',
        'path 1 with pad_brackets=0 produces tight brackets'
    );
};

subtest 'path 1 padded brackets (test builder with args)' => sub {
    my $e = source2pi(
        'test-data/foo.t',
        'use Test::More import => [qw( ok )];',
        { pad_brackets => 1 },
    );
    is(
        $e->formatted_ppi_statement,
        'use Test::More import => [ qw( done_testing ok ) ];',
        'path 1 with pad_brackets=1 produces padded brackets'
    );
};

done_testing();
