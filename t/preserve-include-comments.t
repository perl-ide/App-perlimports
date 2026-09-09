#!perl

# Comments embedded in an include statement (e.g. a "## no critic"
# annotation) must not be discarded when perlimports rewrites the
# statement. See https://github.com/perl-ide/App-perlimports/issues/50.

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use TestHelper                 qw( logger );
use Test::More import => [qw( done_testing is like subtest )];

sub tidied {
    my ($text) = @_;
    my @log;
    my $doc = App::perlimports::Document->new(
        logger          => logger( \@log ),
        ppi_document    => PPI::Document->new( \$text ),
        filename        => 'none',
        preserve_unused => 0,
    );
    return $doc->tidied_document;
}

subtest 'comment between module name and import list is preserved' => sub {
    my $got = tidied(<<'EOT');
use List::Util    ## no critic (SomePolicy)
    qw( first max );
first { $_ } (1);
max( 1, 2 );
EOT
    is( $got, <<'EOT', 'comment re-attached as a trailing side comment' );
use List::Util qw( first max );    ## no critic (SomePolicy)
first { $_ } (1);
max( 1, 2 );
EOT
};

subtest 'comment already trailing the statement is preserved' => sub {
    my $got = tidied(<<'EOT');
use List::Util qw( first max );    ## no critic (SomePolicy)
first { $_ } (1);
max( 1, 2 );
EOT
    is( $got, <<'EOT', 'trailing comment kept in place' );
use List::Util qw( first max );    ## no critic (SomePolicy)
first { $_ } (1);
max( 1, 2 );
EOT
};

subtest 'comment preserved when rewritten to an empty import list' => sub {
    my $got = tidied(<<'EOT');
use POSIX    ## no critic (SomePolicy)
    ();
POSIX::floor(1.5);
EOT
    is( $got, <<'EOT', 'comment kept on a "use Module ();" rewrite' );
use POSIX ();    ## no critic (SomePolicy)
POSIX::floor(1.5);
EOT
};

subtest 'comment nested inside the import list parens is preserved' => sub {
    my $got = tidied(<<'EOT');
use POSIX (
    ## no critic (SomePolicy)
    'floor', 'ceil'
);
floor(1.5);
ceil(2.5);
EOT
    is(
        $got,
        <<'EOT', 'comment nested in "( ... )" re-attached as trailing' );
use POSIX qw( ceil floor );    ## no critic (SomePolicy)
floor(1.5);
ceil(2.5);
EOT
};

subtest 'comment preserved and indent kept on a wrapped import list' => sub {
    my $got = tidied(<<'EOT');
use POSIX    ## no critic (SomePolicy)
    qw( floor ceil strftime setlocale LC_ALL INT_MAX INT_MIN DBL_MAX pow );
floor(1); ceil(1); strftime(q{});
setlocale(LC_ALL); pow( 2, 3 );
my @x = ( INT_MAX, INT_MIN, DBL_MAX );
EOT
    like(
        $got,
        qr/\);\s+## no critic \(SomePolicy\)\n/,
        'comment appended after the closing ");" of a wrapped list',
    );
    like(
        $got,
        qr/\n {4}ceil\n/,
        'perlimports 4-space indent is not re-flowed by perltidy',
    );
};

done_testing();
