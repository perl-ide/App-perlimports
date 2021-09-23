use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'ok' ];

my ($doc) = doc(
    filename        => 'test-data/fully-qualified.pl',
    preserve_unused => 0,
    tidy_whitespace => 0,
);

ok( $doc->_is_used_fully_qualified('List::Util'), 'find List::Util' );
ok( !$doc->_is_used_fully_qualified('Encode'),    'cannot find Encode' );
ok( $doc->_is_used_fully_qualified('JSON::PP'),   'find JSON::PP' );
ok( $doc->_is_used_fully_qualified('HTTP::Tiny'), 'find HTTP::Tiny' );

my $expected = <<'EOF';
use strict;
use warnings;

use lib 'test-data/lib';

use List::Util ();
use Carp qw( croak );
use HTTP::Tiny ();
use JSON::PP qw( encode_json );
use Local::ViaExporter ();
use Test::Builder ();
use POSIX         ();

my @foo = List::Util::uniq( 0 .. 10 );
my $bar = encode_json( {} );
my $hr  = JSON::PP->new;
local *HTTP::Tiny::new = sub { 1 };

sub foo { croak() }

sub some_func {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
}

sub ok {
    return @POSIX::EXPORT_OK;
}

sub also_ok {
    return %Local::ViaExporter::foo;
}
EOF
eq_or_diff( $doc->tidied_document, $expected, 'used modules not removed' );

done_testing;
