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

# Multiple blank-separated sections are each sorted independently, and the
# blank line between sections is preserved.
{
    my ($document) = doc(
        filename       => 'test-data/sort-includes-multi.pl',
        ignore_modules => [qw( Foo Bar Zoo Apple )],
        sort           => 1,
    );
    my $expected = <<'EOF';
use strict;

use Bar;
use Foo;

use Apple;
use Zoo;

1;
EOF
    eq_or_diff(
        $document->tidied_document, $expected,
        'multiple sections each sorted independently'
    );
}

# Leading and trailing comments travel with their imports through the tidy
# path: the leading "# uses Foo" and the trailing "# foo trailing" both stay
# attached to Foo when it sorts below Bar.
{
    my ($document) = doc(
        filename       => 'test-data/sort-includes-comments.pl',
        ignore_modules => [qw( Foo Bar )],
        sort           => 1,
    );
    my $expected = <<'EOF';
use Bar;
# uses Foo
use Foo; # foo trailing

1;
EOF
    eq_or_diff(
        $document->tidied_document, $expected,
        'leading and trailing comments travel with their import'
    );
}

# Sorting is idempotent through the Document tidy path: running --sort on
# already-sorted output yields byte-identical output.
{
    my ($document) = doc(
        filename       => 'test-data/sort-includes-sorted.pl',
        ignore_modules => [qw( Foo Bar Baz )],
        sort           => 1,
    );
    my $expected = <<'EOF';
use strict;

use Bar;
use Baz;
use Foo;

1;
EOF
    eq_or_diff(
        $document->tidied_document, $expected,
        'already-sorted input is unchanged through tidy (idempotent)'
    );
}

done_testing();
