use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is' ];

my $doc = App::perlimports::Document->new(
    filename => 't/lib/UsesMoo.pm',
);

my $expected = <<'EOF';
package UsesMoo;

use Moo;

__PACKAGE__->meta->make_immutable;
1;
EOF

is(
    $doc->tidied_document,
    $expected,
    'document unchanged'
);

done_testing();
