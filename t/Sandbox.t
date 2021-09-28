use strict;
use warnings;

use App::perlimports::Sandbox ();
use Test::More import => [ 'cmp_ok', 'done_testing', 'ok' ];

my $pkg1 = App::perlimports::Sandbox::pkg_for('fakeblock');
my $pkg2 = App::perlimports::Sandbox::pkg_for('fakeblock');

ok( $pkg1, 'first pkg' );
ok( $pkg2, 'second pkg' );

cmp_ok( $pkg1, 'ne', $pkg2, 'names are not the same' );

{
    my $eval = App::perlimports::Sandbox::eval_pkg(
        'Carp',
        'use Carp qw( croak );',
    );

    ok( !$eval, 'no problems with eval' );
}

{
    my $eval = App::perlimports::Sandbox::eval_pkg(
        'Carp',
        'use Local::ZZZ::XXX ();',
    );

    ok( $eval, 'could not eval' );
}

done_testing();
