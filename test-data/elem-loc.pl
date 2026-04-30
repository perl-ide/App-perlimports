use strict;
use warnings;
use version; our $VERSION = qv('v1.0.0');

  use Cpanel::JSON::XS 4.19 qw(encode_json);
use Test::Script 1.27 qw( script_compiles script_runs
    script_stderr_is script_stderr_like);
use Getopt::Long 2.40 qw();

my $foo = decode_json( { foo => 'bar' } );
my @foo = GetOptions();

my $bar = <<EOM;
 some   $foo text @{[ $VERSION ]} \n\t\f pai'ge
EOM
script_compiles();
script_runs();
script_stderr_is();
script_stderr_like();
