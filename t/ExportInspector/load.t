use strict;
use warnings;

use App::perlimports::ExportInspector ();
use Test::More import => [ 'done_testing', 'is_deeply', 'ok', 'subtest' ];
use Test::Needs qw( Import::Into );
use Test::Warnings ();

use lib 'test-data/lib';

# Test::Most imports a lot of functions. any() in particular will clash with an
# import of List::Util qw( any ). So, Test::Warnings will fail if we try to
# import duplicate symbol names in ExportInspector.
subtest 'Test::Most' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'Test::Most' );
    ok( $ei->has_default_exports,  'found export' );
    ok( $ei->has_combined_exports, 'found combined_exports' );
    ok( !$ei->has_errors,          'no errors' );
};

subtest 'List::Util' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'List::Util' );

    ok( !$ei->has_default_exports, 'found no export' );
    ok( $ei->has_combined_exports, 'found combined_exports' );
    ok( !$ei->has_errors,          'no errors' );
};

# UsesMoose.pm literally just includes a "use Moose;"
subtest 'UsesMoose' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'Local::UsesMoose' );
    ok( !$ei->has_errors,     'no errors' );
    ok( $ei->is_oo_class,     'is oo class' );
    ok( !$ei->is_moose_class, 'Not a Moose class' );
    is_deeply( $ei->class_isa, ['Moose::Object'], 'ISA Moose::Object' );
};

# UsesMoo.pm literally just includes a "use Moo;"
subtest 'UsesMoo' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'Local::UsesMoo' );
    ok( !$ei->has_errors,     'no errors' );
    ok( $ei->is_oo_class,     'is oo class' );
    ok( !$ei->is_moose_class, 'Not a Moose class' );
    is_deeply( $ei->class_isa, ['Moo::Object'], 'ISA Moo::Object' );
};

# Check ISA here
subtest 'MyOwnMoose' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'Local::MyOwnMoose' );
    ok( !$ei->has_errors, 'no errors' );
    is_deeply(
        $ei->combined_exports,
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
        'combined exports'
    );
    ok( !$ei->is_oo_class,   'is OO class' );
    ok( $ei->is_moose_class, 'class with imported Moose' );
    is_deeply( $ei->class_isa, ['Moose::Object'], 'class_isa' );
};

done_testing();
