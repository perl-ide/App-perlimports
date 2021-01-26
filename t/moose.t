use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use TestHelper qw( source2pi );
use Test::More import =>
    [ 'diag', 'done_testing', 'is', 'is_deeply', 'ok', 'subtest' ];

subtest 'Moose' => sub {
    my $doc
        = App::perlimports::Document->new( filename => 't/lib/UsesMoose.pm' );

    my $expected = <<'EOF';
package UsesMoose;

use Moose;

has foo => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;
1;
EOF

    is(
        $doc->tidied_document,
        $expected,
        'document unchanged'
    );
};

subtest 'Import::Into' => sub {
    my $doc = App::perlimports::Document->new(
        filename => 't/lib/MyOwnMoose.pm',
    );

    my $expected = <<'EOF';
package MyOwnMoose;

use strict;
use warnings;

use Import::Into;

sub import {
    $_->import::into( scalar caller ) for qw( Moose );
}

1;
EOF

    is(
        $doc->tidied_document,
        $expected,
    );
};

subtest 'Uses MyOwnMoose' => sub {
    my $doc = App::perlimports::Document->new(
        filename => 't/lib/UsesMyOwnMoose.pm',
    );

    my $expected = <<'EOF';
package UsesMyOwnMoose;

use strict;
use warnings;

use MyOwnMoose;

1;
EOF

    is(
        $doc->tidied_document,
        $expected,
    );
};

done_testing();
