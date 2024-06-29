use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing )];

my ( $doc, $log ) = doc(
    filename => 'test-data/lib/Local/Round.pm', preserve_unused => 0,
);

my $expected = <<'END';
package Local::Round;
use parent 'Exporter';

use strict;
use warnings;

use Math::Round qw( nearest );
our @EXPORT_OK = qw(round);

sub round {
    my ( $number, $places ) = @_;
    return nearest( 10**-$places, $number );
}

1;
END

eq_or_diff(
    $doc->tidied_document,
    $expected,
    'locally defined sub is not ignored'
);

done_testing();
