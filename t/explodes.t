use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'is' ];

my ( $doc, $log ) = doc(
    filename        => 'test-data/explodes.pl',
    preserve_unused => 0,
);

my $expected = <<'EOF';
use strict;
use warnings;

use Local::Explodes qw( foo );

foo();
EOF

is(
    $doc->tidied_document,
    $expected,
    'modules which throw exceptions are ignored'
);

done_testing;
