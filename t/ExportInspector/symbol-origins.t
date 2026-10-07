#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::ExportInspector ();
use TestHelper                        qw( logger );
use Test::More import => [qw( done_testing is is_deeply subtest )];
use Test::Warnings ();

sub ei {
    my @log    = ();
    my $module = shift;
    return App::perlimports::ExportInspector->new(
        logger      => logger( \@log ),
        module_name => $module,
    );
}

subtest 're-exporter is disambiguated by true origin' => sub {
    my $ei      = ei('Local::OriginReexporter');
    my $origins = $ei->symbol_origins;

    is(
        $origins->{defined_here},
        'Local::OriginReexporter',
        'natively-defined sub is attributed to the module itself',
    );
    is(
        $origins->{imported_from_source},
        'Local::OriginSource',
        're-exported sub is attributed to its true origin package',
    );

    is_deeply(
        [ sort $ei->reexported_symbols ],
        ['imported_from_source'],
        'reexported_symbols lists only the foreign symbol',
    );
};

subtest 'native module reports no re-exports' => sub {
    my $ei      = ei('Local::OriginSource');
    my $origins = $ei->symbol_origins;

    is(
        $origins->{imported_from_source}, 'Local::OriginSource',
        'imported_from_source is attributed to Local::OriginSource',
    );
    is_deeply(
        [ $ei->reexported_symbols ], [],
        'no re-exports for a self-contained module',
    );
};

subtest 'exportable name without a sub is skipped' => sub {
    my $origins = ei('Local::OriginMissingSub')->symbol_origins;

    is_deeply(
        $origins,
        { defined_here => 'Local::OriginMissingSub' },
        'only the defined sub has an origin',
    );
};

subtest 'module which cannot be loaded has no origins' => sub {
    my $ei = ei('Local::Does::Not::Exist');

    is_deeply( $ei->symbol_origins,         {}, 'no origins' );
    is_deeply( [ $ei->reexported_symbols ], [], 'no re-exports' );
};

done_testing();
