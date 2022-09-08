#!/usr/bin/env perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing is subtest )];
use Test::Needs qw( Import::Into Moose );

subtest 'Moose' => sub {
    my ($doc) = doc(
        filename        => 'test-data/lib/Local/UsesMoose.pm',
        preserve_unused => 1,
    );

    my $expected = <<'EOF';
package Local::UsesMoose;

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
    my ($doc) = doc(
        filename        => 'test-data/lib/Local/MyOwnMoose.pm',
        preserve_unused => 1,
    );

    my $expected = <<'EOF';
package Local::MyOwnMoose;

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
        'tidied_document'
    );
};

subtest 'Uses MyOwnMoose' => sub {
    my ($doc) = doc(
        filename        => 'test-data/lib/Local/UsesMyOwnMoose.pm',
        preserve_unused => 1,
    );

    my $expected = <<'EOF';
package Local::UsesMyOwnMoose;

use strict;
use warnings;

use Local::MyOwnMoose;

1;
EOF

    is(
        $doc->tidied_document,
        $expected,
        'tidied_document'
    );
};

done_testing();
