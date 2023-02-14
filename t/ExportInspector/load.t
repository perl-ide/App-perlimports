#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::ExportInspector ();
use TestHelper                        qw( logger );
use Test::More import => [qw( done_testing is_deeply ok subtest )];
use Test::Needs    qw( Import::Into Moose Test::Most );
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

# Check ISA here
subtest 'Local::MyOwnMoose' => sub {
    my ($ei) = ei('Local::MyOwnMoose');
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
    ok( !$ei->is_oo_class, 'is OO class' );
    is_deeply( $ei->pkg_isa, ['Moose::Object'], 'class_isa' );
    ok( $ei->is_moose_class, 'class with imported Moose' );
};

# Test::Most imports a lot of functions. any() in particular will clash with an
# import of List::Util qw( any ). So, Test::Warnings will fail if we try to
# import duplicate symbol names in ExportInspector.
subtest 'Test::Most' => sub {
    my ($ei) = ei('Test::Most');
    ok( $ei->has_implicit_exports, 'found export' );
    ok( $ei->has_explicit_exports, 'found explicit_exports' );
};

subtest 'List::Util' => sub {
    my ($ei) = ei('List::Util');

    # It does override $a and $b, but I'm not sure if that's helpful for our
    # purposes.
    is_deeply(
        $ei->implicit_exports,
        {},
        'no implicit exports'
    );

    ok( $ei->has_explicit_exports, 'found explicit_exports' );
};

# UsesMoose.pm literally just includes a "use Moose;"
subtest 'Local::UsesMoose' => sub {
    my ($ei) = ei('Local::UsesMoose');
    ok( $ei->is_oo_class,     'is oo class' );
    ok( !$ei->is_moose_class, 'Not a Moose class' );
    ok( $ei->uses_moose,      'uses Moose' );
    is_deeply( $ei->class_isa, ['Moose::Object'], 'ISA Moose::Object' );
};

# UsesMoo.pm literally just includes a "use Moo;"
subtest 'Local::UsesMoo' => sub {
    my ($ei) = ei('Local::UsesMoo');
    ok( $ei->is_oo_class,     'is oo class' );
    ok( !$ei->is_moose_class, 'Not a Moose class' );
    is_deeply( $ei->class_isa, ['Moo::Object'], 'ISA Moo::Object' );
};

subtest 'IO::Socket' => sub {
    my ($ei) = ei('IO::Handle');
    ok( !$ei->is_moose_class, 'Not a Moose class' );
    is_deeply( $ei->class_isa, ['Exporter'], 'ISA Exporter' );
    is_deeply( $ei->at_export, [],           'at_export' );
    ok( scalar @{ $ei->at_export_ok }, 'at_export_ok' );
    is_deeply( $ei->at_export_fail, [], 'at_export_fail' );
    is_deeply( $ei->at_export_tags, [], 'at_export_tags' );
    ok( !$ei->has_implicit_exports,             'no implicit_exports' );
    ok( scalar keys %{ $ei->explicit_exports }, 'explicit_exports' );
};

subtest 'Local::ViaSubExporter' => sub {
    my ($ei) = ei('Local::ViaSubExporter');
    ok( !$ei->is_moose_class, 'Not a Moose class' );
    is_deeply( $ei->class_isa, [], 'no ISA' );
    is_deeply( $ei->at_export, [], 'at_export' );
    ok( !scalar @{ $ei->at_export_ok }, 'no export_ok' );
    is_deeply( $ei->at_export_fail, [], 'no export_fail' );
    is_deeply( $ei->at_export_tags, [], 'no export_tags' );
    ok( !$ei->has_implicit_exports, 'no implicit_exports' );
    is_deeply(
        $ei->explicit_exports, { bar => 'bar', foo => 'foo', },
        'has some explicit exports'
    );
};

subtest 'IO::Socket::INET' => sub {
    my ($ei) = ei('IO::Socket::INET');
    ok( !$ei->is_moose_class, 'Not a Moose class' );
    is_deeply( $ei->class_isa,      ['IO::Socket'], 'ISA IO::Socket' );
    is_deeply( $ei->at_export,      [],             'at_export' );
    is_deeply( $ei->at_export_ok,   [],             'at_export_ok' );
    is_deeply( $ei->at_export_fail, [],             'at_export_fail' );
    is_deeply( $ei->at_export_tags, [],             'at_export_tags' );
    ok( $ei->has_implicit_exports, 'no implicit_exports' );
};

subtest 'Local::Explodes' => sub {
    my ($ei) = ei('Local::Explodes');
    ok( $ei->has_fatal_error, 'has_fatal_error' );
};

done_testing();
