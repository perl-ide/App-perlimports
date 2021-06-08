use strict;
use warnings;

use Getopt::Long qw(:config bundling no_ignore_case);

sub thing {
    GetOptions ("length=i");
}
