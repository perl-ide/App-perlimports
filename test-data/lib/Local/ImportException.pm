package Local::ImportException;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw( exceptional );

sub import {
    my $pkg = shift;
    my $first_arg = shift;
    if ( $first_arg && $first_arg eq 'exceptional' ) {
        die 'oof';
    }
}

sub exceptional {}

1;
