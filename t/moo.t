#!/usr/bin/env perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'is', 'subtest' ];
use Test::Needs qw( Import::Into );

subtest 'Moo' => sub {
    my ($doc) = doc(
        filename  => 'test-data/lib/Local/UsesMoo.pm',
        selection => 'use Moo;'
    );

    is(
        $doc->tidied_document,
        'use Moo;',
        'document unchanged'
    );
};

subtest 'Import::Into' => sub {
    my ($doc) = doc(
        filename => 'test-data/lib/Local/MyOwnMoo.pm',
    );

    my $expected = <<'EOF';
package Local::MyOwnMoo;

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
    my ($doc) = doc(
        filename => 'test-data/lib/Local/UsesMyOwnMoo.pm',
    );

    my $expected = <<'EOF';
package Local::UsesMyOwnMoo;

use strict;
use warnings;

use Local::MyOwnMoo;

1;
EOF

    is(
        $doc->tidied_document,
        $expected,
    );
};

done_testing();
