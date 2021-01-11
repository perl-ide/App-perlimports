use strict;
use warnings;

use App::perlimports ();
use Test::More import => [ 'done_testing', 'is' ];

use lib 't/lib';

my $e = App::perlimports->new(
    filename    => 'test-data/messy-imports.pl',
    source_text => 'use MooseTypeLibrary;',
);

my $expected = <<'EOF';
use MooseTypeLibrary qw(
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
