use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'is_deeply' ];
use Test::Needs qw( Lingua::EN::Inflect );

my ($doc) = doc(
    filename => 'test-data/cast-in-regex.pl', preserve_unused => 0,
);

is_deeply( $doc->interpolated_symbols, {}, 'vars' );

my $expected = <<'END';
use strict;
use warnings;


my $thing = 'B';
if ( $thing =~ m{ \A b }x ) { ... }
END

eq_or_diff(
    $doc->tidied_document,
    $expected,
    'Did not mistake \A for A() provided by Lingua::EN::Inflect'
);

done_testing();
