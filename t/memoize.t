#!perl

use strict;
use warnings;

# This is a regression test for an error which occurs when using
# "memoize('is_function_call')" in Include.pm. It appears only in cases where
# the CLI is processing multiple files in a specific order. In the bug
# scenario, "use MooseX::Types::UUID ();" in test-data/b.pl is transformed to
# "use MooseX::Types::UUID qw( UUID );", despite the fact that "UUID" is not an
# imported symbol in b.pl. This happens in the case where "a.pl" is process
# first and "is_function_call('UUID')" has already been memoized.
#
# We use "memoize" on "is_function_call" because it was identified as a hotspot
# in earlier profiling.

use Test::More import => [qw( done_testing )];

# Loading the UUID XS module wedges prove at process exit on macOS: the test
# passes but the worker never exits, hanging CI at the runner time limit. The
# behaviour under test (memoization of is_function_call in Include.pm) is
# platform-independent, so skip on darwin. This BEGIN must precede the
# Test::Needs line below, which itself require()s UUID. See the macOS notes in
# .github/workflows/dzil-build-and-test.yml.
BEGIN {
    Test::More::plan( skip_all =>
            'Loading the UUID XS module hangs prove at exit on macOS' )
        if $^O eq 'darwin';
}

use lib 't/lib';

use Path::Tiny        qw( path );
use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::Needs       qw( MooseX::Types::UUID UUID );

{
    my ($doc) = doc( filename => 'test-data/a.pl' );
    $doc->tidied_document;
}

{
    my ($doc) = doc( filename => 'test-data/b.pl', preserve_unused => 1, );
    eq_or_diff(
        $doc->tidied_document,
        path('test-data/b.pl')->slurp,
        'doc has not changed'
    );
}

done_testing();
