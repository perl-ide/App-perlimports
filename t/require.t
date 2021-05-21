#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Path::Tiny qw( path );
use TestHelper qw( doc source2pi );
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

my $filename = 'test-data/require.pl';

subtest 'replace top level require via snippet' => sub {
    my $e = source2pi(
        $filename,
        'require LWP::UserAgent;',
    );

    ok( !$e->_is_ignored, 'is not ignored' );
    is(
        $e->formatted_ppi_statement,
        q{use LWP::UserAgent ();},
        'formatted_ppi_statement'
    );
};

my $content = path($filename)->slurp;
my ($doc) = PPI::Document->new( \$content );

my $includes = $doc->find(
    sub {
        $_[1]->isa('PPI::Statement::Include');
    }
) || [];

subtest 'replace top level require from document' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[2] },
    );

    ok( !$e->_is_ignored, 'is not ignored' );
    is(
        $e->formatted_ppi_statement,
        q{use LWP::UserAgent ();},
        'formatted_ppi_statement'
    );
};

subtest 'preserve require inside if block' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[3] },
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        q{require WWW::Mechanize;},
        'formatted_ppi_statement'
    );
};

subtest 'preserve require inside postfix if defined' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[4] },
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        q{require Carp if $ENV{BAR};},
        'formatted_ppi_statement'
    );
};

subtest 'do not import fully qualified function calls' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[5] },
    );

    is(
        $e->formatted_ppi_statement,
        q{use List::Util ();},
        'formatted_ppi_statement'
    );
};

subtest 'preserve require inside postfix if eq' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[6] },
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        q{require Time::Local if $^O eq 'MacOS';},
        'formatted_ppi_statement'
    );
};

subtest 'require rewritten as use' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[7] },
    );

    ok( !$e->_is_ignored, 'is not ignored' );
    is(
        $e->formatted_ppi_statement,
        q{use Cwd ();},
        'formatted_ppi_statement'
    );
};

subtest 'require Exporter not rewritten' => sub {
    my ($doc) = doc(
        filename => 'test-data/lib/Local/RequireExporter.pm',
    );

    my $expected = <<'EOF';
package Local::RequireExporter;

use strict;
use warnings;

require Exporter;
our @EXPORT = qw(foo);

sub foo { return 'from sub foo' }

1;
EOF

    is(
        $doc->tidied_document,
        $expected,
        'statement is unchanged'
    );
};

done_testing();
