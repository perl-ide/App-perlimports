#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use PPI::Document ();
use TestHelper    qw( doc );
use Test::More import => [qw( diag done_testing is ok subtest )];

# GH#197: when the same symbol is imported from more than one module, it must
# stay imported by at least one of them. It is kept on the last import, since
# that is the one which wins at runtime.

sub _doc {
    my $source = shift;
    return doc(
        filename     => 'none',
        ppi_document => PPI::Document->new( \$source ),
        @_,
    );
}

sub _script {
    my $imports = shift;
    my $calls   = shift;
    return <<"EOF";
use strict;
use warnings;

$imports
$calls
EOF
}

my @cases = (
    {
        name    => 'same symbol only, two modules',
        imports => "use Local::MaxA qw( max );\nuse Local::MaxB qw( max );",
        calls   => 'max();',
        tidied  => 'use Local::MaxB qw( max );',
    },
    {
        name    => 'same symbol plus other symbols, two modules',
        imports =>
            "use Local::MaxA qw( max a_only );\nuse Local::MaxB qw( max b_only );",
        calls  => 'max(); a_only(); b_only();',
        tidied =>
            "use Local::MaxA qw( a_only );\nuse Local::MaxB qw( b_only max );",
    },
    {
        name    => 'same symbol only, re-exported by a facade',
        imports =>
            "use Local::MaxA qw( max );\nuse Local::MaxFacade qw( max );",
        calls  => 'max();',
        tidied => 'use Local::MaxFacade qw( max );',
    },
    {
        name    => 'same symbol plus other symbols, re-exported by a facade',
        imports =>
            "use Local::MaxA qw( max );\nuse Local::MaxFacade qw( max facade_only );",
        calls  => 'max(); facade_only();',
        tidied => 'use Local::MaxFacade qw( facade_only max );',
    },
);

for my $case (@cases) {
    subtest "tidy without preserve_unused: $case->{name}" => sub {
        my ($doc) = _doc(
            _script( $case->{imports}, $case->{calls} ),
            preserve_unused => 0,
        );
        is(
            $doc->tidied_document,
            _script( $case->{tidied}, $case->{calls} ),
            'used symbol is still imported'
        );
    };
}

subtest 'tidy with preserve_unused: same symbol only, two modules' => sub {
    my ($doc) = _doc( _script( $cases[0]{imports}, $cases[0]{calls} ) );
    is(
        $doc->tidied_document,
        _script(
            "use Local::MaxA ();\nuse Local::MaxB qw( max );",
            $cases[0]{calls}
        ),
        'max is kept on the last import'
    );
};

for my $case ( @cases[ 0, 1 ] ) {
    for my $preserve_unused ( 0, 1 ) {
        subtest
            "lint (preserve_unused => $preserve_unused): $case->{name}" =>
            sub {
            my ( $doc, $log ) = _doc(
                _script( $case->{imports}, $case->{calls} ),
                lint            => 1,
                preserve_unused => $preserve_unused,
            );
            is( $doc->linter_success, q{}, 'lint fails' );

            my $diff = join "\n",
                map { $_->{message} }
                grep { $_->{message} =~ /^[-+]/m } @{$log};

            # MaxB must either be left alone or be rewritten to keep max.
            ok(
                       $diff !~ m{^-use Local::MaxB\b}m
                    || $diff =~ m{^\+use Local::MaxB\b.*\bmax\b}m,
                'lint does not ask MaxB to drop max'
            ) or diag $diff;
            ok(
                $diff =~ m{^-use Local::MaxA}m,
                'lint asks to change the MaxA import'
            ) or diag $diff;
            };
    }
}

done_testing();
