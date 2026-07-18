#!perl

use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use App::perlimports::Sorter ();
use Test::Differences        qw( eq_or_diff );
use TestHelper               qw( logger );
use Test::More import => [qw( done_testing )];

sub sorted {
    my $source = shift;
    return App::perlimports::Sorter->new(
        logger => logger( [] ),
        source => $source,
    )->sorted_document;
}

# 1. Basic sort of a contiguous section.
eq_or_diff(
    sorted("use Foo;\nuse Bar;\nuse Baz;\n"),
    "use Bar;\nuse Baz;\nuse Foo;\n",
    'basic sort',
);

# 2. Pragma hoisted, blank line injected, modules sorted.
eq_or_diff(
    sorted("use Foo;\nuse strict;\nuse Bar;\n"),
    "use strict;\n\nuse Bar;\nuse Foo;\n",
    'pragma hoisted with injected blank line',
);

# 3. Two blank-separated sections sorted independently.
eq_or_diff(
    sorted("use Foo;\nuse Bar;\n\nuse Zoo;\nuse Apple;\n"),
    "use Bar;\nuse Foo;\n\nuse Apple;\nuse Zoo;\n",
    'independent sections',
);

# 4. An annotated anchor keeps its slot; others fill around it.
eq_or_diff(
    sorted("use Charlie;\nuse Bravo; ## no perlimports\nuse Alpha;\n"),
    "use Alpha;\nuse Bravo; ## no perlimports\nuse Charlie;\n",
    'annotated module anchored, others fill slots',
);

# 5. Attached leading comments travel with their import.
eq_or_diff(
    sorted("# uses Foo\nuse Foo;\n# uses Bar\nuse Bar;\n"),
    "# uses Bar\nuse Bar;\n# uses Foo\nuse Foo;\n",
    'leading comments travel',
);

# 6. String require is an anchor (empty ->module), not sorted.
eq_or_diff(
    sorted(qq{use Foo;\nrequire "config.pl";\nuse Bar;\n}),
    qq{use Bar;\nrequire "config.pl";\nuse Foo;\n},
    'string require anchored',
);

# 7. require Module sorts alongside use Module.
eq_or_diff(
    sorted("use Foo;\nrequire Bar;\n"),
    "require Bar;\nuse Foo;\n",
    'require Module sorts with use',
);

# 8. Version + pragmas hoisted in original order.
eq_or_diff(
    sorted("use Foo;\nuse 5.010;\nuse strict;\nuse Bar;\n"),
    "use 5.010;\nuse strict;\n\nuse Bar;\nuse Foo;\n",
    'version and pragma hoisted, order preserved',
);

# 9. Already-sorted input is unchanged (byte-identical).
eq_or_diff(
    sorted("use Apple;\nuse Banana;\n"),
    "use Apple;\nuse Banana;\n",
    'already sorted is a no-op',
);

# 10. Idempotency: sorting twice yields identical output.
{
    my $once  = sorted("use Foo;\nuse strict;\nuse Bar;\n");
    my $twice = sorted($once);
    eq_or_diff( $twice, $once, 'sorting is idempotent' );
}

# 11. A block-form disabled region is not reordered.
eq_or_diff(
    sorted("## no perlimports\nuse Zebra;\nuse Ant;\n## use perlimports\n"),
    "## no perlimports\nuse Zebra;\nuse Ant;\n## use perlimports\n",
    'block-form annotation region left intact',
);

# 12. Bug 1a: multiple includes on one physical line are left unchanged
# (a shared-line section cannot be safely reordered).
eq_or_diff(
    sorted("use Zoo; use strict; use Apple;\n"),
    "use Zoo; use strict; use Apple;\n",
    'shared-line section left unchanged',
);

# 13. Bug 1b: the shared-line bail is per-section, not global. A normal
# separate-line section still sorts while the shared-line section stays intact.
eq_or_diff(
    sorted("use Zoo; use Apple;\n\nuse Foo;\nuse Bar;\n"),
    "use Zoo; use Apple;\n\nuse Bar;\nuse Foo;\n",
    'shared-line section left intact, normal section still sorted',
);

# 14. Bug 2: a final include without a trailing newline must not be jammed
# onto one line, and the missing trailing newline must be preserved.
eq_or_diff(
    sorted("use Foo;\nuse Bar;"),
    "use Bar;\nuse Foo;",
    'no trailing newline preserved, not jammed',
);

# 15. Idempotency for the no-trailing-newline case.
{
    my $once  = sorted("use Foo;\nuse Bar;");
    my $twice = sorted($once);
    eq_or_diff( $twice, $once, 'no-trailing-newline sort is idempotent' );
}

done_testing();
