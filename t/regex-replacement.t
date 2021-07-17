use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [ '$TODO', 'diag', 'done_testing', 'is' ];
use Test::Needs { 'IP::Random' => '1.200230' };

my ($doc) = doc(
    filename        => 'test-data/regex-replacement.pl',
    preserve_unused => 0,
);

my $expected = <<'EOF';
use IP::Random ();
s/($RE{net}{IPv4})/${\( $store{$1} ||= IP::Random::random_ipv4() )}/g;
EOF

is(
    $doc->tidied_document, $expected,
    'function found in regex replacement'
);

done_testing();
