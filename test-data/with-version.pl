use strict;
use warnings;

use Cpanel::JSON::XS 4.19 qw( encode_json );
use Getopt::Long 2.40 qw();
use LWP::UserAgent 6.49;
use Test::Script 1.27 qw(
    script_compiles
    script_runs
    script_stderr_is
    script_stderr_like
);

my $foo = decode_json( { foo => 'bar' } );
my @foo = GetOptions();

script_compiles();
script_runs();
script_stderr_is();
script_stderr_like();
