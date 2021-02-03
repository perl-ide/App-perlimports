use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is', 'subtest' ];

subtest 'Moo' => sub {
    my $doc = App::perlimports::Document->new(
        filename  => 't/lib/UsesMoose.pm',
        selection => 'use Moo;'
    );

    is(
        $doc->tidied_document,
        'use Moo;',
        'document unchanged'
    );
};

subtest 'Import::Into' => sub {
    my $doc = App::perlimports::Document->new(
        filename => 't/lib/MyOwnMoo.pm',
    );

    my $expected = <<'EOF';
package MyOwnMoo;

use strict;
use warnings;

use Import::Into;

sub import {
    $_->import::into( scalar caller ) for qw( Moo );
}

1;
EOF

    is(
        $doc->tidied_document,
        $expected,
    );
};

subtest 'Uses MyOwnMoo' => sub {
    my $doc = App::perlimports::Document->new(
        filename => 't/lib/UsesMyOwnMoo.pm',
    );

    my $expected = <<'EOF';
package UsesMyOwnMoo;

use strict;
use warnings;

use MyOwnMoo;

1;
EOF

    is(
        $doc->tidied_document,
        $expected,
    );
};

done_testing();
