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
ok( $doc->_is_used_fully_qualified('HTTP::Tiny'), 'find HTTP::Tiny' );

my $expected = <<'EOF';
use strict;
use warnings;

use List::Util ();
use Carp qw( croak );
use HTTP::Tiny ();
use JSON::PP qw( encode_json );
use Test::Builder ();

my @foo = List::Util::uniq( 0 .. 10 );
my $bar = encode_json( {} );
my $hr = JSON::PP->new;
local *HTTP::Tiny::new = sub { 1 };

sub foo { croak() }

sub some_func {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
}
EOF
is( $doc->tidied_document, $expected, 'used modules are not removed' );

done_testing;
