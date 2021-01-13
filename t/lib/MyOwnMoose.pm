package MyOwnMoose;

use strict;
use warnings;

use Import::Into;

sub import {
    $_->import::into( scalar caller )
        for qw( Moose MooseX::StrictConstructor namespace::autoclean );
}

1;
