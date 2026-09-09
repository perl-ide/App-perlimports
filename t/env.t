#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing subtest )];

# Env ties environment variables to Perl variables. There is no @EXPORT to
# discover: whatever you import is exactly what you asked for. So perlimports
# treats the arguments of each "use Env" statement as its own exportable
# symbols and prunes the ones which are not used. See GH #23.

subtest 'used array import is preserved' => sub {
    my ($doc) = doc( filename => 'test-data/env.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Env qw( @PATH );

my @copy = @PATH;
EOF
    eq_or_diff(
        $doc->tidied_document,
        $expected,
        '@PATH is kept because it is used',
    );
};

subtest 'unused import is pruned to an empty list' => sub {
    my ($doc) = doc( filename => 'test-data/env-unused.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Env ();

my $x = 1;
EOF
    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'unused @PATH becomes use Env ()',
    );
};

subtest 'mixed imports keep only the used symbol' => sub {
    my ($doc) = doc( filename => 'test-data/env-mixed.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Env qw( @PATH );

my @copy = @PATH;
EOF
    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'unused $HOME is dropped, used @PATH is kept',
    );
};

subtest 'bareword scalar import is preserved as written' => sub {
    my ($doc) = doc( filename => 'test-data/env-scalar.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Env qw( HOME );

my $h = $HOME;
EOF
    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'bareword HOME is kept (and not rewritten to $HOME) because $HOME is used',
    );
};

subtest 'interpolated scalar counts as used' => sub {
    my ($doc) = doc( filename => 'test-data/env-interpolated.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Env qw( HOME );

print "home is $HOME\n";
EOF
    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'HOME is kept because $HOME is interpolated into a string',
    );
};

subtest 'module version is preserved while pruning' => sub {
    my ($doc) = doc( filename => 'test-data/env-version.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Env 1.00 qw( @PATH );

my @copy = @PATH;
EOF
    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'the version stays, unused $HOME is dropped, used @PATH is kept',
    );
};

subtest 'bare use Env is left untouched' => sub {
    my ($doc) = doc( filename => 'test-data/env-bare.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Env;

my $h = $HOME;
EOF
    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'a bare "use Env;" imports everything and has no args to prune',
    );
};

done_testing();
