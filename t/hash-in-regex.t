use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is $TODO )];

my ($doc) = doc( filename => 'test-data/hash-in-regex.pl' );
my $expected = <<'EOF';
use strict;
use warnings;

use Config qw( $Config );

sub foo {
    return $INC{'Foo.pm'} =~ /^\Q$Config{sitelibexp}/;
}
EOF

TODO: {
    local $TODO = 'Cannot find hash var in regex yet';
    is( $doc->tidied_document, $expected, 'var found' );
}

done_testing();
