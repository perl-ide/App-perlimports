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

# Heredocs always add a trailing newline; strip it for cases that must
# exercise source lacking a final newline.
sub no_trailing_nl {
    my $s = shift;
    chomp $s;
    return $s;
}

eq_or_diff(
    sorted(<<'IN'),
use Foo;
use Bar;
use Baz;
IN
    <<'OUT',
use Bar;
use Baz;
use Foo;
OUT
    'basic sort',
);

eq_or_diff(
    sorted(<<'IN'),
use Foo;
use strict;
use Bar;
IN
    <<'OUT',
use strict;

use Bar;
use Foo;
OUT
    'pragma hoisted with injected blank line',
);

eq_or_diff(
    sorted(<<'IN'),
use Foo;
use Bar;

use Zoo;
use Apple;
IN
    <<'OUT',
use Bar;
use Foo;

use Apple;
use Zoo;
OUT
    'independent sections',
);

eq_or_diff(
    sorted(<<'IN'),
use Charlie;
use Bravo; ## no perlimports
use Alpha;
IN
    <<'OUT',
use Alpha;
use Bravo; ## no perlimports
use Charlie;
OUT
    'annotated module anchored, others fill slots',
);

eq_or_diff(
    sorted(<<'IN'),
# uses Foo
use Foo;
# uses Bar
use Bar;
IN
    <<'OUT',
# uses Bar
use Bar;
# uses Foo
use Foo;
OUT
    'leading comments travel',
);

eq_or_diff(
    sorted(<<'IN'),
use Foo;
require "config.pl";
use Bar;
IN
    <<'OUT',
use Bar;
require "config.pl";
use Foo;
OUT
    'string require anchored',
);

eq_or_diff(
    sorted(<<'IN'),
use Foo;
require Bar;
IN
    <<'OUT',
require Bar;
use Foo;
OUT
    'require Module sorts with use',
);

eq_or_diff(
    sorted(<<'IN'),
use Foo;
use 5.010;
use strict;
use Bar;
IN
    <<'OUT',
use 5.010;
use strict;

use Bar;
use Foo;
OUT
    'version and pragma hoisted, order preserved',
);

eq_or_diff(
    sorted(<<'IN'),
use Apple;
use Banana;
IN
    <<'OUT',
use Apple;
use Banana;
OUT
    'already sorted is a no-op',
);

{
    my $once = sorted(<<'IN');
use Foo;
use strict;
use Bar;
IN
    my $twice = sorted($once);
    eq_or_diff( $twice, $once, 'sorting is idempotent' );
}

eq_or_diff(
    sorted(<<'IN'),
## no perlimports
use Zebra;
use Ant;
## use perlimports
IN
    <<'OUT',
## no perlimports
use Zebra;
use Ant;
## use perlimports
OUT
    'block-form annotation region left intact',
);

# A shared-line section cannot be safely reordered, so multiple includes on
# one physical line are left unchanged.
eq_or_diff(
    sorted(<<'IN'),
use Zoo; use strict; use Apple;
IN
    <<'OUT',
use Zoo; use strict; use Apple;
OUT
    'shared-line section left unchanged',
);

# The shared-line bail is per-section, not global: a normal separate-line
# section still sorts while the shared-line section stays intact.
eq_or_diff(
    sorted(<<'IN'),
use Zoo; use Apple;

use Foo;
use Bar;
IN
    <<'OUT',
use Zoo; use Apple;

use Bar;
use Foo;
OUT
    'shared-line section left intact, normal section still sorted',
);

# A final include without a trailing newline must not be jammed onto one line,
# and the missing trailing newline must be preserved.
eq_or_diff(
    sorted( no_trailing_nl(<<'IN') ),
use Foo;
use Bar;
IN
    no_trailing_nl(<<'OUT'),
use Bar;
use Foo;
OUT
    'no trailing newline preserved, not jammed',
);

{
    my $once = sorted( no_trailing_nl(<<'IN') );
use Foo;
use Bar;
IN
    my $twice = sorted($once);
    eq_or_diff( $twice, $once, 'no-trailing-newline sort is idempotent' );
}

# In byte order 'S' (0x53) sorts before 'n' (0x6E), so a case-sensitive sort
# would keep SOAP first; case-insensitive ordering puts namespace first. (Both
# names are non-pragma: a bare lowercase word like 'strict' is a pragma, but
# 'namespace::clean' is not.)
eq_or_diff(
    sorted(<<'IN'),
use SOAP::Lite;
use namespace::clean;
IN
    <<'OUT',
use namespace::clean;
use SOAP::Lite;
OUT
    'sort key is case-insensitive',
);

eq_or_diff(
    sorted(<<'IN'),
use Foo; # keep foo
use Bar; # keep bar
IN
    <<'OUT',
use Bar; # keep bar
use Foo; # keep foo
OUT
    'trailing same-line comment travels with its import',
);

eq_or_diff(
    sorted(<<'IN'),
use Zoo qw(
  a
  b
);
use Apple;
IN
    <<'OUT',
use Apple;
use Zoo qw(
  a
  b
);
OUT
    'multi-line use statement moves as a block',
);

eq_or_diff(
    sorted(<<'IN'),
use Foo;
no Bar;
use Apple;
IN
    <<'OUT',
use Apple;
no Bar;
use Foo;
OUT
    'non-pragma no Module is anchored, others fill slots',
);

eq_or_diff(
    sorted(<<'IN'),
use Foo;
require Foo;
IN
    <<'OUT',
use Foo;
require Foo;
OUT
    'equal keys retain original relative order (stable sort)',
);

eq_or_diff(
    sorted(<<'IN'),
# a
# b
use Foo;
use Bar;
IN
    <<'OUT',
use Bar;
# a
# b
use Foo;
OUT
    'multiple leading comment lines travel together',
);

eq_or_diff(
    sorted(<<'IN'),
use strict;
use warnings;
IN
    <<'OUT',
use strict;
use warnings;
OUT
    'pragmas-only section is a no-op',
);

eq_or_diff(
    sorted(<<'IN'),
use Zebra;
use Mango; ## no perlimports
use Apple;
use Beta; ## no perlimports
IN
    <<'OUT',
use Apple;
use Mango; ## no perlimports
use Zebra;
use Beta; ## no perlimports
OUT
    'multiple anchors keep slots while sortables fill the rest',
);

# The heredoc body contains lines that look like includes; the line-splice
# sorter must leave them byte-for-byte untouched.
eq_or_diff(
    sorted(<<'IN'),
use Foo;
use Bar;

my $x = <<'END';
use ZZZ;
use AAA;
END
IN
    <<'OUT',
use Bar;
use Foo;

my $x = <<'END';
use ZZZ;
use AAA;
END
OUT
    'heredoc content is not treated as includes',
);

# Source with no include statements is returned unchanged.
eq_or_diff(
    sorted(<<'IN'),
my $x = 1;
my $y = 2;
IN
    <<'OUT',
my $x = 1;
my $y = 2;
OUT
    'source with no includes is a no-op',
);

# Source PPI cannot parse is returned unchanged rather than dying.
eq_or_diff(
    sorted("\x00\x01\x02"),
    "\x00\x01\x02",
    'unparseable source is returned unchanged',
);

done_testing();
