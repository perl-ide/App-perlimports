use strict;
use warnings;

use App::perlimports::Include ();
use Test::More import => [ 'done_testing', 'is' ];

{
    my $AA = 'use Foo     qw( bar );';
    my $BB = 'use Foo qw( bar );';

    is(
        App::perlimports::Include::_respace_include($AA),
        $BB,
        'spaces before parens are stripped'
    );
}

{
    my $AA = 'use Foo      ();';
    my $BB = 'use Foo ();';

    is(
        App::perlimports::Include::_respace_include($AA),
        $BB,
        'spaces before empty parens are stripped'
    );
}

{
    my $AA = 'use Foo  1.2.3   qw( bar );';
    my $BB = 'use Foo  1.2.3 qw( bar );';

    is(
        App::perlimports::Include::_respace_include($AA),
        $BB,
        'spaces before versions are not stripped'
    );
}

done_testing();
