package Local::Sort;

use strict;
use warnings;

use Exporter qw( import );

our $AAA     = 1;
our $AAA_2FA = 1;
our @BBB     = ();
our %CCC     = ();

sub bbb     { }
sub bba_2fa { }

our @EXPORT_OK = (
    '$AAA',
    '$AAA_2FA',
    'bbb',
    'bba_2fa',
    '@BBB',
    '%CCC',
);

1;
