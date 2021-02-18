use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::ExportInspector ();
use TestHelper qw( logger );
use Test::More import => [ 'done_testing', 'is_deeply', 'ok', 'subtest' ];
use Test::Needs qw( Import::Into Moose );
use Test::Warnings ();

sub ei {
    my @log;
    my $module = shift;
    return (
        App::perlimports::ExportInspector->new(
            logger      => logger( \@log ),
            module_name => $module,
        ),
        \@log
    );
}

# Test::Most imports a lot of functions. any() in particular will clash with an
# import of List::Util qw( any ). So, Test::Warnings will fail if we try to
# import duplicate symbol names in ExportInspector.
subtest 'Test::Most' => sub {
    my ( $ei, $log ) = ei('Test::Most');
    ok( $ei->has_default_exports,  'found export' );
    ok( $ei->has_explicit_exports, 'found explicit_exports' );
    ok( !@$log,                    'no errors' );
};

subtest 'List::Util' => sub {
    my ( $ei, $log ) = ei('List::Util');

    ok( !$ei->has_default_exports, 'found no export' );
    ok( $ei->has_explicit_exports, 'found explicit_exports' );
    ok( !@$log,                    'no errors' );
};

# UsesMoose.pm literally just includes a "use Moose;"
subtest 'Local::UsesMoose' => sub {
    my ( $ei, $log ) = ei('Local::UsesMoose');
    ok( $ei->is_oo_class,     'is oo class' );
    ok( !$ei->is_moose_class, 'Not a Moose class' );
    is_deeply( $ei->class_isa, ['Moose::Object'], 'ISA Moose::Object' );
    ok( !@$log, 'no errors' );
};

# UsesMoo.pm literally just includes a "use Moo;"
subtest 'Local::UsesMoo' => sub {
    my ( $ei, $log ) = ei('Local::UsesMoo');
    ok( $ei->is_oo_class,     'is oo class' );
    ok( !$ei->is_moose_class, 'Not a Moose class' );
    is_deeply( $ei->class_isa, ['Moo::Object'], 'ISA Moo::Object' );
    ok( !@$log, 'no errors' );
};

# Check ISA here
subtest 'Local::MyOwnMoose' => sub {
    my ( $ei, $log ) = ei('Local::MyOwnMoose');
    is_deeply(
        $ei->explicit_exports,
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
        'explicit exports'
    );
    ok( !$ei->is_oo_class,   'is OO class' );
    ok( $ei->is_moose_class, 'class with imported Moose' );
    is_deeply( $ei->class_isa, ['Moose::Object'], 'class_isa' );
    ok( !@$log, 'no errors' );
};

done_testing();
