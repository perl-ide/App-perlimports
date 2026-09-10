#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc logger );
use Test::More import => [qw( done_testing is is_deeply ok subtest $TODO )];

=head1 DUPLICATE IMPORTS

How does perl handle importing symbols of the same name from different
packages? The answer is, perl doesn't. Exporting of symbols into other
packages is very flexible, it all depends on the methods used for each
package. So, the C<import> method from one package may happily overwrite
any previously defined symbol (probably causing perl to issue a
"redefined" warning -- you didn't turn those off, did you?), and indeed,
this is the the behavior of L<Exporter> (a very commonly used import
method).  However, any package may define its own C<import> method with
different behavior (not overwriting).

All of this means that, if multiple packages -could- provide an unknown
symbol to the code under analysis, perlimports can't be certain which
package actually provided the resulting symbol (without actually executing
each package's C<import> method together).

Our goal should be: if two modules -are- exporting the same symbol,
regardless whether implicitly or explicitly, we should keep both include
statements but make the symbols explicit (tidy), and log a warning (lint).
A developer can then see (because we made it explicit) that the symbol
appears in two places.

Currently we do not do this.

=head2 Test Code

In this specific code under analysis "socket.pl", we are importing the
same symbol from two packages:

 use IO::Socket::INET;                    # imports 170 symbols implicitly
 use Socket qw(SO_REUSEPORT SOL_SOCKET);  # imports 2 duplicates

Now L<IO::Socket::INET> inherits from L<IO::Socket>, which has an C<import>
method that uses C<Exporter::export> to import symbols from L<Socket> into
its caller. When no list is specified, it imports all 170 symbols listed in
Socket's C< @EXPORT >.
Socket inherits its own C<import> method directly from Exporter.

Exporter's C<import> method will overwrite any previously defined symbols
(causing perl to elicit a "redefined" warning).  So the net result in this
case is that the imported symbol definition came from the second use
statement, package Socket.  (Of course in this case it didn't matter because
the two packages both ultimately provided exactly the same definition.)

=cut

subtest tidy => sub {
    my ($doc) = doc(
        filename => 'test-data/socket.pl',
    );

    # with preserve-unused (default), both use statements are kept
    # but changed: symbols are imported from latter package.
    my $expected = <<'EOF';
use strict;
use warnings;

use IO::Socket::INET ();
use Socket qw( SO_REUSEPORT SOL_SOCKET );

foo( SO_REUSEPORT, SOL_SOCKET );
sub foo { }
EOF

    eq_or_diff(
        $doc->tidied_document,
        $expected,
        'Two modules with the same exports do not get conflated'
    );

    is_deeply $doc->found_imports, {
            'IO::Socket::INET' => [],
            Socket => [ qw( SO_REUSEPORT SOL_SOCKET ) ],
        }, 'found_imports indicates the latter package';
};

subtest tidy_unused => sub {
    my ($doc) = doc(
        filename        => 'test-data/socket.pl',
        preserve_unused => 0,
    );

    # without preserve-unused, at least one statement should be kept.
    # perhaps we'd prefer the latter.  for example,
    my $expected = <<'EOF';
use strict;
use warnings;

use Socket qw( SO_REUSEPORT SOL_SOCKET );

foo( SO_REUSEPORT, SOL_SOCKET );
sub foo { }
EOF

    TODO: {
        local $TODO = 'fix duplicate imports';
        eq_or_diff(
            $doc->tidied_document,
            $expected,
            'One include statement was excised as unused',
        );
    }

    # TODO: the found_imports value for the "unused" package should be the
    # same as when the preserve_unused flag is true!
    # e.g.: empty arrayref or undef. pick one and be consistent.
    is_deeply $doc->found_imports, {
            'IO::Socket::INET' => undef,
            Socket             => [ qw( SO_REUSEPORT SOL_SOCKET ) ],
        }, 'found_imports indicates the latter package';
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

    # TODO: empty arrayref or undef. pick one and be consistent.
    is_deeply $doc->found_imports, {
            'IO::Socket::INET' => undef,
            Socket => [ qw( SO_REUSEPORT SOL_SOCKET ) ],
        }, 'found_imports indicates the latter package';

    # the linting logs should indicate that -one- of the two include
    # statements should import the symbols.  perhaps the latter one?

    ## no critic (ValuesAndExpressions::ProhibitImplicitNewlines)
    TODO: {
        local $TODO = 'fix lint logs for duplicate symbol';
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
+use Socket qw( SO_REUSEPORT SOL_SOCKET );
',
            },

        ],
        'linting errors logged'
    );
    }
};

done_testing;

