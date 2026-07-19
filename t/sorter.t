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

eq_or_diff(
    sorted("use Foo;\nuse Bar;\nuse Baz;\n"),
    "use Bar;\nuse Baz;\nuse Foo;\n",
    'basic sort',
);

eq_or_diff(
    sorted("use Foo;\nuse strict;\nuse Bar;\n"),
    "use strict;\n\nuse Bar;\nuse Foo;\n",
    'pragma hoisted with injected blank line',
);

eq_or_diff(
    sorted("use Foo;\nuse Bar;\n\nuse Zoo;\nuse Apple;\n"),
    "use Bar;\nuse Foo;\n\nuse Apple;\nuse Zoo;\n",
    'independent sections',
);

eq_or_diff(
    sorted("use Charlie;\nuse Bravo; ## no perlimports\nuse Alpha;\n"),
    "use Alpha;\nuse Bravo; ## no perlimports\nuse Charlie;\n",
    'annotated module anchored, others fill slots',
);

eq_or_diff(
    sorted("# uses Foo\nuse Foo;\n# uses Bar\nuse Bar;\n"),
    "# uses Bar\nuse Bar;\n# uses Foo\nuse Foo;\n",
    'leading comments travel',
);

eq_or_diff(
    sorted(qq{use Foo;\nrequire "config.pl";\nuse Bar;\n}),
    qq{use Bar;\nrequire "config.pl";\nuse Foo;\n},
    'string require anchored',
);

eq_or_diff(
    sorted("use Foo;\nrequire Bar;\n"),
    "require Bar;\nuse Foo;\n",
    'require Module sorts with use',
);

eq_or_diff(
    sorted("use Foo;\nuse 5.010;\nuse strict;\nuse Bar;\n"),
    "use 5.010;\nuse strict;\n\nuse Bar;\nuse Foo;\n",
    'version and pragma hoisted, order preserved',
);

eq_or_diff(
    sorted("use Apple;\nuse Banana;\n"),
    "use Apple;\nuse Banana;\n",
    'already sorted is a no-op',
);

{
    my $once  = sorted("use Foo;\nuse strict;\nuse Bar;\n");
    my $twice = sorted($once);
    eq_or_diff( $twice, $once, 'sorting is idempotent' );
}

eq_or_diff(
    sorted("## no perlimports\nuse Zebra;\nuse Ant;\n## use perlimports\n"),
    "## no perlimports\nuse Zebra;\nuse Ant;\n## use perlimports\n",
    'block-form annotation region left intact',
);

# A shared-line section cannot be safely reordered, so multiple includes on
# one physical line are left unchanged.
eq_or_diff(
    sorted("use Zoo; use strict; use Apple;\n"),
    "use Zoo; use strict; use Apple;\n",
    'shared-line section left unchanged',
);

# The shared-line bail is per-section, not global: a normal separate-line
# section still sorts while the shared-line section stays intact.
eq_or_diff(
    sorted("use Zoo; use Apple;\n\nuse Foo;\nuse Bar;\n"),
    "use Zoo; use Apple;\n\nuse Bar;\nuse Foo;\n",
    'shared-line section left intact, normal section still sorted',
);

# A final include without a trailing newline must not be jammed onto one line,
# and the missing trailing newline must be preserved.
eq_or_diff(
    sorted("use Foo;\nuse Bar;"),
    "use Bar;\nuse Foo;",
    'no trailing newline preserved, not jammed',
);

{
    my $once  = sorted("use Foo;\nuse Bar;");
    my $twice = sorted($once);
    eq_or_diff( $twice, $once, 'no-trailing-newline sort is idempotent' );
}

# In byte order 'S' (0x53) sorts before 'n' (0x6E), so a case-sensitive sort
# would keep SOAP first; case-insensitive ordering puts namespace first. (Both
# names are non-pragma: a bare lowercase word like 'strict' is a pragma, but
# 'namespace::clean' is not.)
eq_or_diff(
    sorted("use SOAP::Lite;\nuse namespace::clean;\n"),
    "use namespace::clean;\nuse SOAP::Lite;\n",
    'sort key is case-insensitive',
);

eq_or_diff(
    sorted("use Foo; # keep foo\nuse Bar; # keep bar\n"),
    "use Bar; # keep bar\nuse Foo; # keep foo\n",
    'trailing same-line comment travels with its import',
);

eq_or_diff(
    sorted("use Zoo qw(\n  a\n  b\n);\nuse Apple;\n"),
    "use Apple;\nuse Zoo qw(\n  a\n  b\n);\n",
    'multi-line use statement moves as a block',
);

eq_or_diff(
    sorted("use Foo;\nno Bar;\nuse Apple;\n"),
    "use Apple;\nno Bar;\nuse Foo;\n",
    'non-pragma no Module is anchored, others fill slots',
);

eq_or_diff(
    sorted("use Foo;\nrequire Foo;\n"),
    "use Foo;\nrequire Foo;\n",
    'equal keys retain original relative order (stable sort)',
);

eq_or_diff(
    sorted("# a\n# b\nuse Foo;\nuse Bar;\n"),
    "use Bar;\n# a\n# b\nuse Foo;\n",
    'multiple leading comment lines travel together',
);

eq_or_diff(
    sorted("use strict;\nuse warnings;\n"),
    "use strict;\nuse warnings;\n",
    'pragmas-only section is a no-op',
);

eq_or_diff(
    sorted(
        "use Zebra;\nuse Mango; ## no perlimports\nuse Apple;\nuse Beta; ## no perlimports\n"
    ),
    "use Apple;\nuse Mango; ## no perlimports\nuse Zebra;\nuse Beta; ## no perlimports\n",
    'multiple anchors keep slots while sortables fill the rest',
);

# The heredoc body contains lines that look like includes; the line-splice
# sorter must leave them byte-for-byte untouched.
eq_or_diff(
    sorted(
        "use Foo;\nuse Bar;\n\nmy \$x = <<'END';\nuse ZZZ;\nuse AAA;\nEND\n"),
    "use Bar;\nuse Foo;\n\nmy \$x = <<'END';\nuse ZZZ;\nuse AAA;\nEND\n",
    'heredoc content is not treated as includes',
);

# Source with no include statements is returned unchanged.
eq_or_diff(
    sorted("my \$x = 1;\nmy \$y = 2;\n"),
    "my \$x = 1;\nmy \$y = 2;\n",
    'source with no includes is a no-op',
);

# Source PPI cannot parse is returned unchanged rather than dying.
eq_or_diff(
    sorted("\x00\x01\x02"),
    "\x00\x01\x02",
    'unparseable source is returned unchanged',
);

done_testing();
