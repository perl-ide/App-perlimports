use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is', 'is_deeply', 'subtest' ];

subtest 'verbose' => sub {
    my $doc
        = App::perlimports::Document->new( filename => 'test-data/carp.pl' );
    my $source_text = 'use Carp qw( croak verbose );';

    my $expected = <<'EOF';
use strict;
use warnings;

use Carp qw( croak verbose );

croak('oof');
EOF
    is(
        $doc->tidied_document,
        $expected,
        'verbose is preserved'
    );
};

subtest 'no verbose' => sub {
    my $doc = App::perlimports::Document->new(
        filename => 'test-data/carp-without-verbose.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Carp qw( croak );

croak('oof');
EOF

    is(
        $doc->tidied_document,
        $expected,
        'verbose is not inserted'
    );
};

subtest 'no imports' => sub {
    my $doc = App::perlimports::Document->new(
        filename => 'test-data/carp-with-no-imports.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Carp qw( croak );

croak('oof');
EOF

    is(
        $doc->tidied_document,
        $expected,
        'verbose is not inserted'
    );

    is_deeply(
        $doc->original_imports->{Carp},
        undef,
        'original imports'
    );
};

done_testing();
