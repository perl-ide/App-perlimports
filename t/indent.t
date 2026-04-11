#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib', 'test-data/lib';
use TestHelper qw( doc );
use Test::More import => [qw( done_testing is subtest )];

subtest 'default indent' => sub {
    my ($doc) = doc( filename => 'test-data/long-list.pl' );
    is(
        $doc->tidied_document,
        <<'EOF', 'default indent is 4 spaces' );
use strict;
use warnings;

use lib 'test-data/lib';

use Local::LongList qw(
    alpha
    bravo
    charlie
    delta
    echo
    foxtrot
    golf
    hotel
    india
    juliet
);

alpha();
bravo();
charlie();
delta();
echo();
foxtrot();
golf();
hotel();
india();
juliet();
EOF
};

subtest 'indent=2' => sub {
    my ($doc) = doc(
        filename => 'test-data/long-list.pl',
        indent   => 2,
    );
    is(
        $doc->tidied_document,
        <<'EOF', 'indent=2 produces 2-space indent' );
use strict;
use warnings;

use lib 'test-data/lib';

use Local::LongList qw(
  alpha
  bravo
  charlie
  delta
  echo
  foxtrot
  golf
  hotel
  india
  juliet
);

alpha();
bravo();
charlie();
delta();
echo();
foxtrot();
golf();
hotel();
india();
juliet();
EOF
};

subtest 'indent=8' => sub {
    my ($doc) = doc(
        filename => 'test-data/long-list.pl',
        indent   => 8,
    );
    is(
        $doc->tidied_document,
        <<'EOF', 'indent=8 produces 8-space indent' );
use strict;
use warnings;

use lib 'test-data/lib';

use Local::LongList qw(
        alpha
        bravo
        charlie
        delta
        echo
        foxtrot
        golf
        hotel
        india
        juliet
);

alpha();
bravo();
charlie();
delta();
echo();
foxtrot();
golf();
hotel();
india();
juliet();
EOF
};

done_testing();
