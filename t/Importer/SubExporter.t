use strict;
use warnings;

use App::perlimports::Importer::SubExporter ();
use Test::More import =>
    [ 'done_testing', 'is', 'is_deeply', 'ok', 'subtest' ];

use lib 't/lib';

subtest 'Moose Type Library' => sub {
    my $module = 'MooseTypeLibrary';

    my ($inspection)
        = App::perlimports::Importer::SubExporter::maybe_get_exports($module);

    ok( $inspection->has_all_exports, 'exports' );
    is( $inspection->all_exports->{is_Bool}, 'Bool', 'is_ aliased' );
    is( $inspection->all_exports->{to_File}, 'File', 'to_ aliased' );
    ok(
        !exists $inspection->all_exports->{to_Str},
        'Coercion does not exist'
    );
};

subtest 'Moo' => sub {
    my $module = 'Moo';

    my $inspection
        = App::perlimports::Importer::SubExporter::maybe_get_exports($module);

    is_deeply(
        $inspection->default_exports,
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

    is_deeply( $inspection->errors, [] );
};

subtest 'ViaSubExporter' => sub {
    my $module = 'ViaSubExporter';

    my $inspection
        = App::perlimports::Importer::SubExporter::maybe_get_exports($module);

    is_deeply(
        $inspection->all_exports,
        {
            bar => 'bar',
            foo => 'foo',
        },
        'exports'
    );
    is_deeply( $inspection->errors, [] );
};

subtest 'MyOwnMoose' => sub {
    my $module = 'MyOwnMoose';

    my $inspection
        = App::perlimports::Importer::SubExporter::maybe_get_exports($module);

    is_deeply(
        $inspection->all_exports,
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
    is_deeply( $inspection->errors, [] );
};

done_testing();
