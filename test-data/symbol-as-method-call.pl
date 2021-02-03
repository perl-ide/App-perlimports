use strict;
use warnings;

use HTML::TableExtract;
use Object::Tap;

my $te = HTML::TableExtract->new->$_tap(parse => $html);
