use strict;
use warnings;

use App::perlimports::ExportInspector ();
use Test::More import => [ 'done_testing', 'ok', 'subtest' ];
use Test::Warnings ();

# Test::Most imports a lot of functions. any() in particular will clash with an
# import of List::Util qw( any ). So, Test::Warnings will fail if we try to
# import duplicate symbol names in ExportInspector.
subtest 'Test::Most' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'Test::Most' );
    ok( scalar @{ $ei->export },         'found export' );
    ok( !scalar @{ $ei->export_ok },     'no export_ok' );
    ok( keys %{ $ei->combined_exports }, 'found combined_exports' );
    ok( !$ei->has_errors,                'no errors' );
    ok( !$ei->is_moose_type_library,     'not a Moose type library' );
};

subtest 'List::Util' => sub {
    my $ei
        = App::perlimports::ExportInspector->new(
        module_name => 'List::Util' );

    ok( !scalar @{ $ei->export },        'found no export' );
    ok( scalar @{ $ei->export_ok },      'found export_ok' );
    ok( keys %{ $ei->combined_exports }, 'found combined_exports' );
    ok( !$ei->has_errors,                'no errors' );
    ok( !$ei->is_moose_type_library,     'not a Moose type library' );
};

done_testing();
