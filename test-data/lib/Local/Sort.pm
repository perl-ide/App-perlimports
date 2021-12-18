package Local::Sort;

use strict;
use warnings;

use Exporter qw( import );

our $AAA = 1;
our @BBB = ();
our %CCC = ();

sub bbb { }

our @EXPORT_OK = (
    '$AAA',
    'bbb',
    '@BBB',
    '%CCC',
);

1;
