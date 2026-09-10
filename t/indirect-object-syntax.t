use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( done_testing is subtest )];

my ($doc) = doc(
    filename        => 'test-data/indirect-object-syntax.pl',
    preserve_unused => 0,
    tidy_whitespace => 0,
);

# [ module name, is it detected as used?, description ]
my @cases = (
    [ 'File',        1, 'indirect object syntax: new File $path, $data' ],
    [ 'Database',    1, 'indirect object syntax: connect Database $dsn' ],
    [ 'JSON::PP',    1, 'arrow method call still detected: JSON::PP->new' ],
    [ 'Unused',      0, 'use statement is not indirect object usage' ],
    [ 'Forbidden',   0, 'no statement is not indirect object usage' ],
    [ 'Deferred',    0, 'require statement is not indirect object usage' ],
    [ 'Ignored',     0, 'package statement is not indirect object usage' ],
    [ 'Widget',      0, 'sub declaration is not indirect object usage' ],
    [ 'Nonexistent', 0, 'module which never appears is not used' ],
);

subtest 'indirect object syntax detection' => sub {
    for my $case (@cases) {
        my ( $module, $expected, $desc ) = @{$case};
        is(
            ( $doc->_is_used_fully_qualified($module) ? 1 : 0 ),
            $expected, $desc
        );
    }
};

# A module used only via indirect object syntax must be preserved in the
# rewritten document rather than removed as unused.
subtest 'used module is preserved end to end' => sub {
    my ($preserved) = doc(
        filename        => 'test-data/indirect-object-syntax-preserved.pl',
        preserve_unused => 0,
        tidy_whitespace => 0,
    );

    my $expected = <<'EOF';
use strict;
use warnings;

use lib 'test-data/lib';

use Local::NoImport ();

my $obj = new Local::NoImport;
EOF

    eq_or_diff(
        $preserved->tidied_document,
        $expected,
        'use Local::NoImport preserved when used via indirect object syntax'
    );
};

done_testing;
