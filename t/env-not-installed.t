#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing ok subtest )];

# Env is not always installed. Fedora, for instance, ships it in a separate
# perl-Env package. perlimports takes the exports of a "use Env" statement
# from the statement itself, so it should prune unused ones even when Env
# cannot be loaded. See GH #200.
unshift @INC, sub {
    die "Can't locate Env.pm in \@INC (hidden by test)\n"
        if $_[1] eq 'Env.pm';
    return;
};

my $loaded = eval { require Env; 1 };
ok( !$loaded, 'Env cannot be loaded' );

subtest 'unused symbol is pruned' => sub {
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

subtest 'entirely unused import is pruned to an empty list' => sub {
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
        'a bare "use Env;" is still left alone',
    );
};

done_testing();
