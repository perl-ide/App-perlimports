use strict;
use warnings;

use Encode;     ## no critic (Some::Policy)
use List::Util;
use Carp qw( croak );
use HTTP::Tiny;
use JSON::PP;
use Test::Builder ();

my @foo = List::Util::uniq( 0 .. 10 );
my $bar = encode_json( {} );
my $hr = JSON::PP->new;
local *HTTP::Tiny::new = sub { 1 };

sub foo { croak() }

sub some_func {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
}
