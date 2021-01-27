use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is' ];

my $doc
    = App::perlimports::Document->new( filename => 'test-data/builtin.pl' );

my $expected = <<'EOF';
use strict;
use warnings;

use POSIX ();

printf('%s', 'ok');
EOF

is(
    $doc->tidied_document, $expected,
    'Perl builtin does not get added to POSIX imports'
);

done_testing();
