use strict;
use warnings;

use Config;

sub foo {
    return $INC{'Foo.pm'} =~ /^\Q$Config{sitelibexp}/;
}
