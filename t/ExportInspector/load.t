use strict;
use warnings;

use App::perlimports::ExportInspector ();
use Test::More import => [ 'done_testing', 'is_deeply', 'ok', 'subtest' ];
use Test::Warnings ();

use lib 't/lib';

# Test::Most imports a lot of functions. any() in particular will clash with an
# import of List::Util qw( any ). So, Test::Warnings will fail if we try to
# import duplicate symbol names in ExportInspector.
subtest 'Test::Most' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'Test::Most' );
    ok( scalar keys %{ $ei->export },     'found export' );
    ok( !scalar keys %{ $ei->export_ok }, 'no export_ok' );
    ok( keys %{ $ei->combined_exports },  'found combined_exports' );
    ok( !$ei->has_errors,                 'no errors' );
};

subtest 'List::Util' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'List::Util' );

    ok( !scalar keys %{ $ei->export },   'found no export' );
    ok( scalar %{ $ei->export_ok },      'found export_ok' );
    ok( keys %{ $ei->combined_exports }, 'found combined_exports' );
    ok( !$ei->has_errors,                'no errors' );
};

subtest 'UsesMoose' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'UsesMoose' );
    ok( !$ei->has_errors,    'no errors' );
    ok( $ei->is_moose_class, 'is Moose class' );
};

# Check ISA here
subtest 'MyOwnMoose' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'MyOwnMoose' );
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
    ok( $ei->is_moose_class, 'is Moose class' );
};

done_testing();
