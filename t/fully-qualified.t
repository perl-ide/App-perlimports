use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More;

my ($doc) = doc(
    filename        => 'test-data/fully-qualified.pl',
    preserve_unused => 0,
);

ok( $doc->_is_used_fully_qualified('List::Util'), 'find List::Util' );
ok( !$doc->_is_used_fully_qualified('Encode'),    'cannot find Encode' );
ok( $doc->_is_used_fully_qualified('JSON::PP'),   'find JSON::PP' );

my $expected = <<'EOF';
use strict;
use warnings;

use List::Util ();
use Carp qw( croak );
use JSON::PP qw( encode_json );

my @foo = List::Util::uniq( 0 .. 10 );
my $bar = encode_json( {} );
my $hr = JSON::PP->new;

sub foo { croak() }
EOF
is( $doc->tidied_document, $expected, 'used modules are not removed' );

done_testing;
