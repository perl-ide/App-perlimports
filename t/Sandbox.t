use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use App::perlimports::Sandbox ();
use TestHelper                qw( doc );
use Test::Differences         qw( eq_or_diff );
use Test::More import => [qw( cmp_ok diag done_testing ok subtest )];

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

subtest 'real trial-load warning is suppressed' => sub {

    # End-to-end check: trial-load a dependency-free module that has no
    # import() method while passing a non-empty import list -- the same shape
    # as the original report, "use LWP::UserAgent qw( new );". With no import()
    # to hand the list to, Perl emits its actual "Attempt to call
    # undefined/missing import method" warning (the symbol name is irrelevant;
    # only the non-empty list matters -- a bare "use" stays silent). eval_pkg
    # must swallow it so nothing reaches this outer handler, verifying
    # suppression against whatever wording this Perl version uses (see GH #181).
    my @leaked;
    local $SIG{__WARN__} = sub { push @leaked, @_ };

    my $error = App::perlimports::Sandbox::eval_pkg(
        'Local::NoImport',
        'use Local::NoImport qw( new );',
    );

    ok( !$error, 'module trial-loads without error' );
    ok(
        !( grep { m/call (?:undefined|missing) import method/ } @leaked ),
        'no trial-load import-method warning leaks to the outer handler'
    ) or diag "leaked: @leaked";
};

subtest 'trial-load warning recognized across Perl versions' => sub {

    # We deliberately exercise the private predicate directly here.
    ## no critic (Subroutines::ProtectPrivateSubs)

    # Perl reworded this diagnostic from "undefined" to "missing" in the 5.44
    # development cycle (see GH #181). Both wordings must be suppressed so the
    # noise never leaks to the user's terminal, regardless of the running Perl.
    my $args = q{("new") via package "LWP::UserAgent"};
    my $tail
        = ' (Perhaps you forgot to load the package?) at (eval 1) line 1.';

    ok(
        App::perlimports::Sandbox::_is_trial_load_warning(
            "Attempt to call undefined import method with arguments $args$tail"
        ),
        'undefined (Perl <= 5.42) wording is recognized'
    );

    ok(
        App::perlimports::Sandbox::_is_trial_load_warning(
            "Attempt to call missing import method with arguments $args$tail"
        ),
        'missing (Perl >= 5.44) wording is recognized'
    );

    ok(
        !App::perlimports::Sandbox::_is_trial_load_warning(
            'Some other warning we should let through'),
        'unrelated warnings are not suppressed'
    );
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
