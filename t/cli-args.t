use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::CLI ();
use Capture::Tiny         qw( capture );
use Path::Tiny            ();
use TestHelper            qw( logger );
use Test::Differences     qw( eq_or_diff );
use Test::More import => [qw( diag done_testing is like subtest )];
use Test::Needs qw( Perl::Critic::Utils );

subtest 'almost all of the args' => sub {
    my $expected = <<'EOF';
use strict;
use warnings;

use Perl::Critic::Utils qw($QUOTE);

my %foo = (
    $QUOTE => q{description},
);
EOF

    my $log_file = Path::Tiny->tempfile('perlimportsXXXXXXXX');

    local @ARGV = (
        '--ignore-modules'                  => 'CGI,Plack',
        '--ignore-modules-filename'         => 'test-data/ignore-modules.txt',
        '--ignore-modules-pattern'          => '^(Foo|Foo::Bar)',
        '--ignore-modules-pattern-filename' =>
            'test-data/ignore-modules-pattern.txt',
        '--libs'                          => 'lib,t/lib',
        '--never-export-modules'          => 'Never::One,Never::Two',
        '--never-export-modules-filename' =>
            'test-data/never-export-modules.txt',
        '--log-filename' => "$log_file",
        '--log-level'    => 'info',
        '--no-cache',
        '--no-padding',
        '--no-preserve-duplicates',
        '--no-preserve-unused',
        '--no-tidy-whitespace',
        'test-data/var-in-hash-key.pl',
    );
    my $cli = App::perlimports::CLI->new( logger => logger( [] ) );
    my ( $stdout, $stderr ) = capture {
        $cli->run;
    };
    is( $stdout, $expected, 'no exception on args' ) || diag $stderr;

    my $c = $cli->_config;

    is( $c->cache, 0, 'cache' );
    eq_or_diff(
        $c->ignore, [ 'CGI', 'Plack', 'Data::Printer', 'Git::Sub' ],
        'ignore'
    );
    eq_or_diff(
        $c->ignore_pattern, ['^(Foo|Foo::Bar)'],
        'ignore_pattern'
    );
    eq_or_diff( $c->libs, [ 'lib', 't/lib' ], 'libs' );
    like( $c->log_filename, qr{perlimports}, 'log_filename' );
    is( $c->log_level, 'info', 'log_level' );
    eq_or_diff(
        $c->never_export,
        [ 'Never::One', 'Never::Two', 'Never::Three', 'Never::Four', ],
        'never_export'
    );
    is( $c->padding,             0, 'padding' );
    is( $c->preserve_duplicates, 0, 'preserve_duplicates' );
    is( $c->tidy_whitespace,     0, 'tidy_whitespace' );
};

done_testing();
