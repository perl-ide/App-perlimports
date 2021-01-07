use strict;
use warnings;

use App::perlimports ();
use Path::Tiny qw( path );
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

my $filename = 'test-data/require.pl';

subtest 'replace top level require via snippet' => sub {
    my $e = App::perlimports->new(
        filename    => $filename,
        source_text => 'require LWP::UserAgent;',
    );

    ok( !$e->_is_ignored, 'is not ignored' );
    is(
        $e->formatted_ppi_statement,
        q{use LWP::UserAgent ();},
        'formatted_ppi_statement'
    );
};

my $content = path($filename)->slurp;
my $doc     = PPI::Document->new( \$content );

my $includes = $doc->find(
    sub {
        $_[1]->isa('PPI::Statement::Include');
    }
) || [];

is( scalar @{$includes}, 6, 'found 6 includes' );

subtest 'replace top level require from document' => sub {
    my $e = App::perlimports->new(
        filename => $filename,
        include  => $includes->[2],
    );

    ok( !$e->_is_ignored, 'is not ignored' );
    is(
        $e->formatted_ppi_statement,
        q{use LWP::UserAgent ();},
        'formatted_ppi_statement'
    );
};

subtest 'preserve require inside if block' => sub {
    my $e = App::perlimports->new(
        filename => $filename,
        include  => $includes->[3],
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        q{require WWW::Mechanize;},
        'formatted_ppi_statement'
    );
};

subtest 'preserve require inside postfix if' => sub {
    my $e = App::perlimports->new(
        filename => $filename,
        include  => $includes->[4],
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        q{require Carp if $ENV{BAR};},
        'formatted_ppi_statement'
    );
};

subtest 'do not import fully qualified function calls' => sub {
    my $e = App::perlimports->new(
        filename => $filename,
        include  => $includes->[5],
    );

    is(
        $e->formatted_ppi_statement,
        q{use List::Util ();},
        'formatted_ppi_statement'
    );
};

done_testing();
