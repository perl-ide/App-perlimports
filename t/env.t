#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing fail ok plan subtest )];

# Env ties environment variables to Perl variables. There is no @EXPORT to
# discover: whatever you import is exactly what you asked for. So perlimports
# treats the arguments of each "use Env" statement as its own exportable
# symbols and prunes the ones which are not used. See GH #23.
#
# Env is not always installed. Fedora, for instance, ships it in a separate
# perl-Env package. Since the exports come from the statement itself,
# perlimports should give the same results either way, so every case below
# runs both with Env installed and with Env hidden. See GH #200.

my @cases = (
    {
        name     => 'used array import is preserved',
        filename => 'test-data/env.pl',
        expected => <<'EOF',
use strict;
use warnings;

use Env qw( @PATH );

my @copy = @PATH;
EOF
        description => '@PATH is kept because it is used',
    },
    {
        name     => 'unused import is pruned to an empty list',
        filename => 'test-data/env-unused.pl',
        expected => <<'EOF',
use strict;
use warnings;

use Env ();

my $x = 1;
EOF
        description => 'unused @PATH becomes use Env ()',
    },
    {
        name     => 'mixed imports keep only the used symbol',
        filename => 'test-data/env-mixed.pl',
        expected => <<'EOF',
use strict;
use warnings;

use Env qw( @PATH );

my @copy = @PATH;
EOF
        description => 'unused $HOME is dropped, used @PATH is kept',
    },
    {
        name     => 'bareword scalar import is preserved as written',
        filename => 'test-data/env-scalar.pl',
        expected => <<'EOF',
use strict;
use warnings;

use Env qw( HOME );

my $h = $HOME;
EOF
        description =>
            'bareword HOME is kept (and not rewritten to $HOME) because $HOME is used',
    },
    {
        name     => 'interpolated scalar counts as used',
        filename => 'test-data/env-interpolated.pl',
        expected => <<'EOF',
use strict;
use warnings;

use Env qw( HOME );

print "home is $HOME\n";
EOF
        description =>
            'HOME is kept because $HOME is interpolated into a string',
    },
    {
        name     => 'module version is preserved while pruning',
        filename => 'test-data/env-version.pl',
        expected => <<'EOF',
use strict;
use warnings;

use Env 1.00 qw( @PATH );

my @copy = @PATH;
EOF
        description =>
            'the version stays, unused $HOME is dropped, used @PATH is kept',
    },
    {
        name     => 'comma-separated (non-qw) args are handled',
        filename => 'test-data/env-comma.pl',
        expected => <<'EOF',
use strict;
use warnings;

use Env qw( @PATH );

my @copy = @PATH;
EOF
        description =>
            q{'HOME', '@PATH' list drops unused HOME and normalizes to qw()},
    },

    # The whole statement is removed (this is the general unused-module
    # removal path, not specific to Env); the surrounding blank lines are
    # left as-is, as they are for any other removed import.
    {
        name     => 'preserve_unused => 0 removes an entirely unused use Env',
        filename => 'test-data/env-unused.pl',
        args     => { preserve_unused => 0 },
        expected => <<'EOF',
use strict;
use warnings;


my $x = 1;
EOF
        description =>
            'an unused use Env line is deleted, not left as use Env ()',
    },
    {
        name     => 'bare use Env is left untouched',
        filename => 'test-data/env-bare.pl',
        expected => <<'EOF',
use strict;
use warnings;

use Env;

my $h = $HOME;
EOF
        description =>
            'a bare "use Env;" imports everything and has no args to prune',
    },
);

sub run_cases {
    for my $case (@cases) {
        subtest $case->{name} => sub {
            my ($doc) = doc(
                filename => $case->{filename},
                %{ $case->{args} || {} },
            );
            eq_or_diff(
                $doc->tidied_document,
                $case->{expected},
                $case->{description},
            );
        };
    }
}

sub env_loads {
    my $loaded = eval { require Env; 1 };
    return $loaded;
}

subtest 'Env installed' => sub {
    if ( !env_loads() ) {

        # Don't make people install Env just to run the tests, but make sure
        # CI covers this case.
        if ( $ENV{CI} ) {
            fail('Env must be installed in CI');
            return;
        }
        plan skip_all => 'Env is not installed';
    }
    run_cases();
};

subtest 'Env not installed' => sub {
    delete $INC{'Env.pm'};
    local @INC = (
        sub {
            die "Can't locate Env.pm in \@INC (hidden by test)\n"
                if $_[1] eq 'Env.pm';
            return;
        },
        @INC,
    );
    ok( !env_loads(), 'Env cannot be loaded' );
    run_cases();
};

done_testing();
