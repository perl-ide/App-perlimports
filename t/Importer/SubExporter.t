use strict;
use warnings;

use App::perlimports::Importer::SubExporter ();
use Test::More import =>
    [ 'done_testing', 'is', 'is_deeply', 'like', 'ok', 'subtest' ];

subtest 'Moose Type Library' => sub {
    my $module = 'Database::Migrator::Types';

    my ( $exports, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_all_exports(
        $module);

    ok( $exports, 'exports' );
    is( $exports->{is_Bool}, 'Bool', 'is_ aliased' );
    is( $exports->{to_File}, 'File', 'to_ aliased' );
    ok( !$error, 'no error' );
};

subtest 'Moo' => sub {
    my $module = 'Moo';

    my ( $exports, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_all_exports(
        $module);

    is_deeply(
        $exports,
        {
            after   => 'after',
            around  => 'around',
            before  => 'before',
            extends => 'extends',
            has     => 'has',
            ISA     => 'ISA',
            with    => 'with',
        },
        'exports'
    );

    ok( $exports, 'exports' );
    ok( !$error,  'no error' );
};

subtest 'Does not exist' => sub {
    my $module = 'Local::Does::Not::Exist';

    my ( $exports, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_all_exports(
        $module);

    is_deeply(
        $exports,
        {},
        'exports'
    );

    like( $error, qr{you may need to install}, 'error' );
};

subtest 'Git::Helpers' => sub {
    my $module = 'Git::Helpers';

    my ( $exports, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_all_exports(
        $module);

    is_deeply(
        $exports,
        {
            checkout_root       => 'checkout_root',
            current_branch_name => 'current_branch_name',
            https_remote_url    => 'https_remote_url',
            ignored_files       => 'ignored_files',
            is_inside_work_tree => 'is_inside_work_tree',
            remote_url          => 'remote_url',
            travis_url          => 'travis_url',
        },
        'exports'
    );
    ok( !$error, 'no error' );
};
done_testing();
