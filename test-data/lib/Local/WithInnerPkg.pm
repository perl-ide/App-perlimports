
use warnings;

package Local::WithInnerPkg;

use HTTP::Status qw( HTTP_FOUND HTTP_OK );

sub foo {
    HTTP_OK();
}
1;

package MyInnerPkgOne;

use HTTP::Status qw( HTTP_CREATED HTTP_FOUND );

sub foo {
    HTTP_CREATED();
}
1;

package MyInnerPkgTwo;

use HTTP::Status qw( HTTP_ACCEPTED HTTP_FOUND );

sub foo {
    HTTP_ACCEPTED();
}

1;
