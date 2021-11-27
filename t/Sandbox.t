use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use App::perlimports::Sandbox ();
use TestHelper qw( doc );
use Test::Differences qw( eq_or_diff );
use Test::More import => [ 'cmp_ok', 'done_testing', 'ok', 'subtest' ];

my $pkg1 = App::perlimports::Sandbox::pkg_for('fakeblock');
my $pkg2 = App::perlimports::Sandbox::pkg_for('fakeblock');

ok( $pkg1, 'first pkg' );
ok( $pkg2, 'second pkg' );

cmp_ok( $pkg1, 'ne', $pkg2, 'names are not the same' );

subtest 'Carp' => sub {
    my $eval = App::perlimports::Sandbox::eval_pkg(
        'Carp',
        'use Carp qw( croak );',
    );

    ok( !$eval, 'no problems with eval' );
};

subtest 'missing module' => sub {
    my $eval = App::perlimports::Sandbox::eval_pkg(
        'Local::ZZZ::XXX',
        'use Local::ZZZ::XXX ();',
    );

    ok( $eval, 'eval failure' );
};

subtest 'local module' => sub {
    my $eval = App::perlimports::Sandbox::eval_pkg(
        'Local::ImportException',
        'use Local::ImportException ();',
    );

    ok( !$eval, 'no eval failure' );
};

subtest 'local module with exception' => sub {
    my $eval = App::perlimports::Sandbox::eval_pkg(
        'Local::ImportException',
        'use Local::ImportException qw( exceptional );',
    );

    ok( $eval, 'eval failure' );
};

subtest 'eval in tidied_document' => sub {
    my ($doc) = doc( filename => 'test-data/exceptional.pl' );

    my $expected = <<'EOF';
use strict;
use warnings;

use Carp qw( croak );
use Local::ImportException;

exceptional();
croak();
EOF

    eq_or_diff(
        $doc->tidied_document, $expected,
        'does not update import with eval failure'
    );
};
done_testing();
