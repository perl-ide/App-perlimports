#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use TestHelper                 qw( logger );
use Test::More import => [qw( done_testing ok subtest )];

sub chomped {
    my ($str) = @_;
    chomp($str);
    return $str;
}

my @log;

## no critic (Subroutines::ProtectPrivateSubs)
sub make_doc {
    my %args = @_;
    @log = ();
    my $text    = $args{include} || die 'must give an use statement';
    my $ppi_doc = PPI::Document->new( \$text );

    # (lint default is 0, tidy default is 1)
    my $doc = App::perlimports::Document->new(
        logger       => logger( \@log ),
        ppi_document => $ppi_doc,
        filename     => 'none',
        ( lint            => $args{lint} ) x !!defined $args{lint},
        ( tidy_whitespace => $args{tidy} ) x !!defined $args{tidy},
    );
    my $stm = $doc->includes->[0];    # PPI:Statement:Include

    # An empty includes list means the fixture's use statement could not be
    # evaluated in the sandbox (e.g. it relies on a symbol not exported by the
    # installed module version). Fail with a clear message rather than a cryptic
    # "Can't call method ... on an undefined value" from _include_analyzer.
    die "no includes found for: $text" unless $stm;

    my $inc = $doc->_include_analyzer($stm);    # App:perlimports:Include
    return ( $doc, $inc );
}
## use critic

subtest 'tidied include with tidying' => sub {
    my $orig = 'use List::Util     qw( first );';
    my ( $doc, $inc ) = make_doc( include => $orig );
    my $ppis = $inc->_include;                  # PPI:Statement:Include
        # with tidy_whitespace, the only way to get the original back is:
        # * statement was identical already, or,
        # * original had some extra spaces before the symbol list.

    # statements that are rejected (the original statement is kept!)
    my $reject = 'use List::Util qw( first );';
    foreach my $try ( $orig, $reject ) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res == $ppis, 'kept original, rejected: ' . $try );
    }

    # and a list of statements that should replace the original:
    my @tries = split /\n/, <<'EODOC';
use List::Util qw(first);
use List::Util ();
use List::Util qw( first max );
EODOC
    push @tries, chomped(<<'EOTEXT');
use List::Util qw(
    first
);
EOTEXT
    foreach my $try (@tries) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res != $ppis, 'replaced original with: ' . $try );
    }
};

subtest 'tidied include without tidying' => sub {
    my $orig = 'use List::Util     qw( first );';
    my ( $doc, $inc ) = make_doc( include => $orig, tidy => 0 );
    my $ppis = $inc->_include;    # PPI:Statement:Include
        # without tidy_whitespace, always get back the original
        # if the only change was whitespace.

    # statements that are rejected (the original statement is kept!)
    my @rejects = split /\n/, <<'EODOC';
use List::Util qw( first );
use List::Util qw(first);
EODOC
    push @rejects, chomped(<<'EOTEXT');
use List::Util qw(
    first
);
EOTEXT
    foreach my $try ( $orig, @rejects ) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res == $ppis, 'kept original, rejected spacing change' );
    }

    # statements that should replace the original:
    my @tries = split /\n/, <<'EODOC2';
use List::Util ();
use List::Util qw( first max );
EODOC2
    foreach my $try (@tries) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res != $ppis, 'replaced original: different content' );
    }
};

subtest 'tidied include with version and tidying' => sub {
    my $orig = 'use File::Temp 0.23  qw( tempfile tempdir );';
    my ( $doc, $inc ) = make_doc( include => $orig );
    my $ppis = $inc->_include;    # PPI:Statement:Include

    # statement rejected in favor of the original
    my $reject = 'use File::Temp 0.23 qw( tempfile tempdir );';
    foreach my $try ( $orig, $reject ) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res == $ppis, 'kept original, rejected: ' . $try );
    }

    # statements that should replace the original:
    my @tries = ('use File::Temp 0.23 qw(tempfile tempdir);');
    push @tries, chomped(<<'EOTEXT');
use File::Temp 0.23 qw(
    tempfile
    tempdir
);
EOTEXT
    foreach my $try (@tries) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res != $try, 'replaced original with ' . $try );
    }

    # ----------- extra space before version number --------
    # always gets replaced!
    $orig = 'use File::Temp  0.23  qw( tempfile tempdir );';
    ( $doc, $inc ) = make_doc( include => $orig );
    $ppis = $inc->_include;    # PPI:Statement:Include

    # statements that should replace the original:
    @tries = split /\n/, <<'EODOC';
use File::Temp 0.23 qw( tempfile tempdir );
use File::Temp 0.23 qw(tempfile tempdir);
use File::Temp 0.23 ();
EODOC
    push @tries, chomped(<<'EOTEXT2');
use File::Temp 0.23 qw(
    tempfile
    tempdir
);
EOTEXT2
    foreach my $try (@tries) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res != $ppis, 'replaced original with: ' . $try );
    }
};

subtest 'include w version no tidying' => sub {
    my $orig = 'use File::Temp  0.23  qw( tempfile tempdir );';
    my ( $doc, $inc ) = make_doc( include => $orig, tidy => 0 );
    my $ppis = $inc->_include;    # PPI:Statement:Include
        # without tidy_whitespace, always get back the original
        # if the only change was whitespace.

    # statements that are rejected in favor of the original
    my $rejects = <<'EODOC';
use File::Temp 0.23 qw( tempfile tempdir );
use File::Temp 0.23 qw(tempfile tempdir);
EODOC
    foreach my $try ( $orig, split /\n/, $rejects ) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res == $ppis, 'kept original, rejected spacing change' );
    }

    # statements that should replace the original:
    my @tries = split /\n/, <<'EODOC2';
use File::Temp 0.23 qw(tempfile);
use File::Temp 0.23 ();
EODOC2
    push @tries, chomped(<<'EOTEXT');
use File::Temp 0.23 qw(
    tempfile
    tempdir
    mkstemp
);
EOTEXT
    foreach my $try (@tries) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res != $ppis, 'replaced original; different content' );
    }
};

subtest 'multiline include with tidying' => sub {
    my $orig = chomped(<<'EORIG');
use List::Util     qw(
    first
    max
    min
);
EORIG
    my ( $doc, $inc ) = make_doc( include => $orig );
    my $ppis = $inc->_include;    # PPI:Statement:Include
        # with tidy_whitespace, the only way to get the original back is:
        # * statement was identical already, or,
        # * original had some extra spaces before the symbol list.

    # statement that is rejected (the original statement is kept!)
    my $reject = chomped(<<'EOTEXT');
use List::Util qw(
    first
    max
    min
);
EOTEXT
    foreach my $try ( $orig, $reject ) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res == $ppis, 'kept original, rejected spacing change' );
    }

    # statements that should replace the original:
    my @tries = split /\n/, <<'EODOC';
use List::Util qw(first max min);
use List::Util qw( first max min );
EODOC
    foreach my $try (@tries) {
        my $res = $inc->_maybe_get_new_include($try);
        ok( $res != $ppis, 'replaced original with: ' . $try );
    }
};

done_testing();

