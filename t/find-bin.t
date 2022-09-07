#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc source2pi );
use Test::More import => [qw( done_testing is is_deeply ok )];

my $e = source2pi(
    'test-data/find-bin.pl',
    'use FindBin qw( $Bin );',
);
is(
    $e->module_name(), 'FindBin',
    'module_name'
);

ok( !$e->_is_ignored, 'no longer ignored' );
is_deeply( $e->_imports, [qw($Bin)], 'found import' );
eq_or_diff(
    $e->formatted_ppi_statement . q{},
    'use FindBin qw( $Bin );',
    'formatted_ppi_statement'
);

my ($doc) = doc(
    filename        => 'test-data/more-find-bin.pl',
    preserve_unused => 0,
);

my $expected = <<'EOF';
#!/usr/bin/env perl

use FindBin ();

use lib "$FindBin::Bin/../../../lib";
EOF
eq_or_diff(
    $doc->tidied_document, $expected,
    'fully qualified symbol name interpolated into quotes detected'
);

done_testing();
