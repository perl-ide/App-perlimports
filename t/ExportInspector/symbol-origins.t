#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::ExportInspector ();
use TestHelper                        qw( logger );
use Test::More import => [qw( done_testing is is_deeply subtest )];
use Test::Needs    qw( Sub::Identify );
use Test::Warnings ();

sub ei {
    my @log    = ();
    my $module = shift;
    return App::perlimports::ExportInspector->new(
        logger      => logger( \@log ),
        module_name => $module,
    );
}

# A module that both defines a sub natively and re-exports one it imported from
# elsewhere. The export lists cannot distinguish the two; symbol_origins can.
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

# A plain Exporter module whose subs are all its own reports no re-exports.
subtest 'native module reports no re-exports' => sub {
    my $ei      = ei('Local::Round');
    my $origins = $ei->symbol_origins;

    is(
        $origins->{round}, 'Local::Round',
        'round is attributed to Local::Round',
    );
    is_deeply(
        [ $ei->reexported_symbols ], [],
        'no re-exports for a self-contained module',
    );
};

done_testing();
