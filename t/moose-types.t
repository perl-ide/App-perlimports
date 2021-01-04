use strict;
use warnings;

use App::perlimports ();
use Test::More import => [qw( done_testing is is_deeply ok )];

my $e = App::perlimports->new(
    filename    => 'test-data/messy-imports.pl',
    source_text => 'use Database::Migrator::Types;',
);

my $expected = <<'EOF';
use Database::Migrator::Types qw(
    ArrayRef
    Bool
    CodeRef
    FileHandle
    HashRef
    Maybe
    Object
    RegexpRef
    Str
);
EOF
chomp $expected;

is(
    $e->formatted_ppi_statement,
    $expected,
    'formatted_ppi_statement'
);

done_testing();
