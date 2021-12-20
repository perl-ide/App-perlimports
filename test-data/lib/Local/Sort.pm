package Local::Sort;

use strict;
use warnings;

use Exporter qw( import );

our $AAA     = 1;
our $AAA_2FA = 1;
our @BBB     = ();
our %CCC     = ();

sub bbb     { }
sub bbb_2fa { }

our @EXPORT_OK = (
    '$AAA',
    '$AAA_2FA',
    'bbb',
    '@BBB',
    '%CCC',
);

1;
