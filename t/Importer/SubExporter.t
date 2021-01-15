use strict;
use warnings;

use App::perlimports::Importer::SubExporter ();
use Test::More import =>
    [qw( diag done_testing is is_deeply like ok subtest )];

use lib 't/lib';

subtest 'Moose Type Library' => sub {
    my $module = 'MooseTypeLibrary';

    my ( $exports, $attr, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_exports($module);

    ok( $exports, 'exports' );
    is( $exports->{is_Bool}, 'Bool', 'is_ aliased' );
    is( $exports->{to_File}, 'File', 'to_ aliased' );
    ok( !exists $exports->{to_Str}, 'Coercion does not exist' );
    ok( !$error,                    'no error' );
};

subtest 'Moo' => sub {
    my $module = 'Moo';

    my ( $exports, $attr, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_exports($module);

    is_deeply(
        $exports,
        {
            after   => 'after',
            around  => 'around',
            before  => 'before',
            extends => 'extends',
            has     => 'has',
            with    => 'with',
        },
        'exports'
    );

    ok( $exports, 'exports' );
    ok( !$error,  'no error' );
};

subtest 'Does not exist' => sub {
    my $module = 'Local::Does::Not::Exist';

    my ( $exports, $attr, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_exports($module);

    is_deeply(
        $exports,
        {},
        'exports'
    );

    like( $error, qr{you may need to install}, 'error' );
};

subtest 'ViaSubExporter' => sub {
    my $module = 'ViaSubExporter';

    my ( $exports, $attr, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_exports($module);

    is_deeply(
        $exports,
        {
            bar => 'bar',
            foo => 'foo',
        },
        'exports'
    );
    ok( !$error, 'no error' );
};

subtest 'MyOwnMoose' => sub {
    my $module = 'MyOwnMoose';

    my ( $exports, $attr, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_exports($module);

    is_deeply(
        $exports,
        {
            after    => 'after',
            around   => 'around',
            augment  => 'augment',
            before   => 'before',
            blessed  => 'blessed',
            confess  => 'confess',
            extends  => 'extends',
            has      => 'has',
            inner    => 'inner',
            isa      => 'isa',
            meta     => 'meta',
            override => 'override',
            super    => 'super',
            with     => 'with',
        },
        'exports'
    );
    ok( !$error, 'no error' );
};

done_testing();
