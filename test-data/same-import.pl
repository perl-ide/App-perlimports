use strict;
use warnings;

# Both export a tmpdir()
use Test::TempDir::Tiny qw( tempdir );
use Path::Tiny qw( path );

my $path = path('foo');
my $dir = tempdir();
