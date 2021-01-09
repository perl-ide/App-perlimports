use strict;
use warnings;

use IO::Uncompress::Gunzip qw( $GunzipError );

sub load {
    my $fname = 'foo.gz';
    IO::Uncompress::Gunzip->new($fname)
        or die "gzip failed: $GunzipError\n";
}
