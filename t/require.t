#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Path::Tiny qw( path );
use TestHelper qw( doc source2pi );
use Test::More import => [qw( done_testing is like ok subtest unlike )];
use Test::Needs qw( LWP::UserAgent );

my $filename = 'test-data/require.pl';

subtest 'preserve top level require via snippet by default' => sub {
    my $e = source2pi(
        $filename,
        'require LWP::UserAgent;',
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        'require LWP::UserAgent;',
        'require is preserved by default'
    );
};

subtest 'translate top level require via snippet when opted out' => sub {
    my $e = source2pi(
        $filename,
        'require LWP::UserAgent;',
        { preserve_require => 0 },
    );

    ok( !$e->_is_ignored, 'is not ignored' );
    is(
        $e->formatted_ppi_statement,
        'use LWP::UserAgent ();',
        'formatted_ppi_statement'
    );
};

my $content = path($filename)->slurp;
my ($require_doc) = PPI::Document->new( \$content );

my $includes = $require_doc->find(
    sub {
        $_[1]->isa('PPI::Statement::Include');
    }
) || [];

subtest 'preserve top level require from document by default' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[2] },
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        'require LWP::UserAgent;',
        'require is preserved by default'
    );
};

subtest 'translate top level require from document when opted out' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[2], preserve_require => 0 },
    );

    ok( !$e->_is_ignored, 'is not ignored' );
    is(
        $e->formatted_ppi_statement,
        'use LWP::UserAgent ();',
        'formatted_ppi_statement'
    );
};

subtest 'preserve require inside if block' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[3], preserve_require => 0 },
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        'require WWW::Mechanize;',
        'formatted_ppi_statement'
    );
};

subtest 'preserve require inside postfix if defined' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[4], preserve_require => 0 },
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        'require Carp if $ENV{BAR};',
        'formatted_ppi_statement'
    );
};

subtest 'do not import fully qualified function calls when opted out' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[5], preserve_require => 0 },
    );

    is(
        $e->formatted_ppi_statement,
        'use List::Util ();',
        'formatted_ppi_statement'
    );
};

subtest 'preserve require inside postfix if eq' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[6], preserve_require => 0 },
    );

    ok( $e->_is_ignored, 'is ignored' );
    is(
        $e->formatted_ppi_statement,
        q{require Time::Local if $^O eq 'MacOS';},
        'formatted_ppi_statement'
    );
};

subtest 'require rewritten as use when opted out' => sub {
    my $e = source2pi(
        $filename,
        undef,
        { include => $includes->[7], preserve_require => 0 },
    );

    ok( !$e->_is_ignored, 'is not ignored' );
    is(
        $e->formatted_ppi_statement,
        'use Cwd ();',
        'formatted_ppi_statement'
    );
};

subtest 'require Exporter not rewritten' => sub {
    my ($doc) = doc(
        filename         => 'test-data/lib/Local/RequireExporter.pm',
        preserve_require => 0,
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

subtest 'preserve top level require in document by default' => sub {
    my ($doc) = doc(
        filename => $filename,
    );

    my $tidied = $doc->tidied_document;

    like(
        $tidied,
        qr{^require LWP::UserAgent;$}m,
        'require LWP::UserAgent; preserved'
    );
    like(
        $tidied,
        qr{^require Cwd;$}m,
        'require Cwd; preserved'
    );
    unlike(
        $tidied,
        qr{use \s+ (?:LWP::UserAgent|Cwd) \s+ \(\);}x,
        'no requires were translated to use ();'
    );
};

done_testing();
