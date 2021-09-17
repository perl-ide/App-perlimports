use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'is', 'subtest' ];

subtest 'preserve duplicates' => sub {
    my ($doc) = doc(
        filename => 'test-data/dupes.pl',
    );

    my $expected = <<'EOF';
use strict;
use warnings;

use File::Temp qw( tempdir tempfile );
use List::Util qw( any );
use File::Temp qw( tempdir tempfile ); # some comments

sub foo {
    my $dir  = tempdir();
    my $file = tempfile();
    return any { $_ > 1 } ( 0 .. 2 );
}
EOF

    my $got = $doc->tidied_document;

    is(
        $got,
        $expected,
        'duplicate use statement removed'
    );
};

subtest 'strip duplicates' => sub {
    my ($doc) = doc(
        filename            => 'test-data/dupes.pl',
        preserve_duplicates => 0,
    );

    my $expected = <<'EOF';
use strict;
use warnings;

use File::Temp qw( tempdir tempfile );
use List::Util qw( any );

sub foo {
    my $dir  = tempdir();
    my $file = tempfile();
    return any { $_ > 1 } ( 0 .. 2 );
}
EOF

    is(
        $doc->tidied_document,
        $expected,
        'duplicate use statement removed'
    );
};

done_testing;
