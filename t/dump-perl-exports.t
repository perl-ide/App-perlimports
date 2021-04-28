#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw( capture );
use Test::More import => [ 'diag', 'done_testing', 'like', 'ok', 'subtest' ];
use Test::Needs qw( Moose );

subtest 'Moose' => sub {
    my ( undef, $stderr ) = capture {
        run('Moose');
    };
    ok( !$stderr, 'no errors' ) || diag $stderr;
};

subtest 'Moo' => sub {
    my ( undef, $stderr ) = capture {
        run('Moo');
    };
    ok( !$stderr, 'no errors' ) || diag $stderr;
};

subtest 'Not found' => sub {
    my ( undef, $stderr ) = capture {
        run('Local::Does::Not::Exist::Foo');
    };
    like( $stderr, qr{Can't locate}, 'error on module not found' );
};

sub run {
    my $module = shift;
    system(
        'perl', '-Ilib', 'script/dump-perl-exports', '--module',
        $module,
    );
}
done_testing();
