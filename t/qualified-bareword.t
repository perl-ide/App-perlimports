use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing is_deeply )];

my ($doc) = doc(
    filename => 'test-data/qualified-bareword.pl', preserve_unused => 0,
);

is_deeply( $doc->interpolated_symbols, {}, 'vars' );

my $expected = <<'END';
use strict;
use warnings;

use Path::Tiny ();

my $path = Path::Tiny::->new('foo.txt');
END

eq_or_diff(
    $doc->tidied_document,
    $expected,
    'qualified bareword detected as module name'
);

done_testing();
