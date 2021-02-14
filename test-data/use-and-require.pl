use strict;
use warnings;

require IO::File;
use Fcntl;

{
    my $fh;
    sysopen( $fh, 'foo', O_RDONLY )
}
