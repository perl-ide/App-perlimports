use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'is_deeply' ];

my ($doc) = doc(
    filename => 'test-data/lookalike-words.pl', preserve_unused => 0,
);

is_deeply( $doc->interpolated_symbols, {}, 'vars' );

my $expected = <<'END';
my $foo = "this will not croak";
my $bar = <<"EOF"
croak()
EOF
END

eq_or_diff(
    $doc->tidied_document, $expected,
    'croak not mistaken for function'
);

done_testing();
