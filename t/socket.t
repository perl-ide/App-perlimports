#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc logger );
use Test::More import => [qw( done_testing is ok subtest )];

subtest tidy => sub {
    my ($doc) = doc(
        filename => 'test-data/socket.pl',
    );

    my $expected = <<'EOF';
use strict;
use warnings;

use IO::Socket::INET ();
use Socket qw( SO_REUSEPORT SOL_SOCKET );

foo( SO_REUSEPORT, SOL_SOCKET );
sub foo { }
EOF

    is(
        $doc->tidied_document,
        $expected,
        'Two modules with the same exports do not get conflated'
    );

};

subtest lint => sub {
    my @log;
    my $logger = logger( \@log, 'error' );
    my ($doc) = doc(
        filename => 'test-data/socket.pl',
        lint     => 1,
        logger   => $logger,
    );

    ok( !$doc->linter_success, 'fails linting' );

    ## no critic (ValuesAndExpressions::ProhibitImplicitNewlines)
    eq_or_diff(
        \@log,
        [
            {
                level   => 'error',
                message => "\x{274c}"
                    . ' IO::Socket::INET (import arguments need tidying) at test-data/socket.pl line 4',
            },
            {
                level   => 'error',
                message => '@@ -4 +4 @@
-use IO::Socket::INET;
+use IO::Socket::INET ();
',
            },
            {
                level   => 'error',
                message => "\x{274c}"
                    . ' Socket (import arguments need tidying) at test-data/socket.pl line 5',
            },
            {
                level   => 'error',
                message => '@@ -5 +5 @@
-use Socket qw(SO_REUSEPORT SOL_SOCKET);
+use Socket ();
',
            },

        ],
        'linting errors logged'
    );
};

done_testing;
