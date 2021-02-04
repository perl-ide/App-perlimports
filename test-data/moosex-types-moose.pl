use strict;
use warnings;

use MooseX::Types::Moose qw( ArrayRef Str);
use MooseX::Types -declare => [ qw( Module ) ]; # exports subtype, as

subtype Module, as ArrayRef [ Str ];
