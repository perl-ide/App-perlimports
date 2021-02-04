use strict;
use warnings;

# Use this file to generate some before/after examples in Pod and also test
# Moose type imports.

use Local::MooseTypeLibrary qw( HashRef ArrayRef Object Str Bool Maybe CodeRef FileHandle RegexpRef );

is_HashRef();
ArrayRef();
Object();
my $ref = \&is_Str();
Bool();
Maybe();
CodeRef();
FileHandle();
RegexpRef();
is_RegexpRef();
