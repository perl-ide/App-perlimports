use strict;
use warnings;

# Use this file to generate some before/after examples in Pod and also test
# Moose type imports.

use Database::Migrator::Types qw( HashRef ArrayRef Object Str Bool Maybe CodeRef FileHandle RegexpRef );

is_HashRef();
ArrayRef();
Object();
Str();
Bool();
Maybe();
CodeRef();
FileHandle();
RegexpRef();
