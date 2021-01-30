use strict;
use warnings;

use Mojo::Util;

my $class = 'Foo';
if ( $class && ( my $path = $INC{ my $file = class_to_path $class} ) ) {
}
