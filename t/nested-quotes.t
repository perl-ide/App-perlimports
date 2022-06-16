use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing is_deeply )];

my ($doc) = doc( filename => 'test-data/nested-quotes.pl' );

is_deeply(
    $doc->interpolated_symbols, { path => 1, '$thing' => 1, },
    'vars'
);

my $expected = <<'EOF';
use strict;
use warnings;

use Path::Tiny qw( path );

my $thing = qq{content="${ \( path('one/two.txt')->stringify )}"};
print "$thing\n";
EOF

eq_or_diff(
    $doc->tidied_document, $expected,
    'function call in nested quotes detected'
);

done_testing();
