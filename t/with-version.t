use strict;
use warnings;

use lib 't/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper qw( doc );
use Test::More import => [ 'diag', 'done_testing' ];
use Test::Needs qw( Cpanel::JSON::XS LWP::UserAgent );

my ( $doc, $log ) = doc( filename => 'test-data/with-version.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use Cpanel::JSON::XS 4.19 qw( decode_json );
use Getopt::Long 2.40 qw( GetOptions );
use LWP::UserAgent 5.00 ();
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
EOF

eq_or_diff(
    $doc->tidied_document,
    $expected,
    'versions preserved'
) || do { require Data::Dumper; diag Data::Dumper::Dumper($log); };

done_testing();
