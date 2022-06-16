#!/usr/bin/env perl

use strict;
use warnings;

use MooseX::Types::UUID ();
use UUID qw( uuid );

foo(uuid);

sub foo {}
