use strict;
use warnings;

use Encode;
use List::Util;
use Carp qw( croak );
use JSON::PP;

my @foo = List::Util::uniq( 0 .. 10 );
my $bar = encode_json( {} );
my $hr = JSON::PP->new;

sub foo { croak() }
