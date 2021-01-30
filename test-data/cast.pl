use strict;
use warnings;

use Mojo::Util;

my @pairs = map {@$_} @{split_header $str // ''};
