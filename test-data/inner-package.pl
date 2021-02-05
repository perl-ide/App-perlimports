use strict;
use warnings;

use HTTP::Status qw( is_success is_redirect );

package Foo;

sub test_code {
    return ::is_success( shift );
}

package main;

print Foo::test_code(200);
print ::is_redirect(301);
