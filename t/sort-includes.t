#!perl

use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing ok )];

my @ignore = ( 'Foo', 'Bar', 'Baz' );

# sort => 0 leaves ordering untouched.
{
    my ($document) = doc(
        filename       => 'test-data/sort-includes.pl',
        ignore_modules => \@ignore,
    );
    my $expected = <<'EOF';
use strict;
use Foo;
use Bar;
use Baz;

1;
EOF
    eq_or_diff(
        $document->tidied_document, $expected,
        'sort off: unchanged'
    );
}

# sort => 1 hoists the pragma, injects a blank line, sorts the modules.
{
    my ($document) = doc(
        filename       => 'test-data/sort-includes.pl',
        ignore_modules => \@ignore,
        sort           => 1,
    );
    my $expected = <<'EOF';
use strict;

use Bar;
use Baz;
use Foo;

1;
EOF
    eq_or_diff( $document->tidied_document, $expected, 'sort on: sorted' );
}

# Lint mode: unsorted includes fail (linter_success is false).
{
    my ($document) = doc(
        filename       => 'test-data/sort-includes.pl',
        ignore_modules => \@ignore,
        sort           => 1,
        lint           => 1,
    );
    ok( !$document->linter_success, 'lint fails on unsorted includes' );
}

# Lint mode: already-sorted includes pass.
{
    my ($document) = doc(
        filename       => 'test-data/sort-includes.pl',
        ignore_modules => \@ignore,
        sort           => 0,
        lint           => 1,
    );
    ok( $document->linter_success, 'lint passes when sort is disabled' );
}

# Lint mode: already-sorted includes pass with sort enabled.
{
    my ($document) = doc(
        filename       => 'test-data/sort-includes-sorted.pl',
        ignore_modules => \@ignore,
        sort           => 1,
        lint           => 1,
    );
    ok(
        $document->linter_success,
        'lint passes on already-sorted includes with sort enabled'
    );
}

done_testing();
