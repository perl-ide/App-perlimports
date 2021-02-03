package MyOwnMoo;

use strict;
use warnings;

use Import::Into;

sub import {
    $_->import::into( scalar caller ) for qw( Moo );
}

1;
