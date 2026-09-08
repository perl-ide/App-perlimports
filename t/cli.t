#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::CLI ();
use Capture::Tiny         qw( capture );
use Cpanel::JSON::XS      qw( decode_json );
use File::pushd           qw( pushd );
use Path::Tiny            ();
use TestHelper            qw( logger );
use Test::Differences     qw( eq_or_diff );
use Test::Fatal           qw( exception );
use Test::More import => [qw( diag done_testing is like ok subtest )];
use Test::Needs qw( Perl::Critic::Utils );

subtest 'bad path to config file' => sub {
    local @ARGV = (
        '--config-file',
        'test-data/XXX',
        'test-data/a.pl',
    );

    ok( App::perlimports::CLI->new, '_config_file builder is lazy' );
    like(
        exception { App::perlimports::CLI->new->run }, qr{XXX not found},
        'not found'
    );
};

# Emulate a user with no local or global config file
subtest 'no config files' => sub {
    my $dir = Path::Tiny->tempdir('testconfigXXXXXXXX');
    local $ENV{XDG_CONFIG_HOME} = "$dir";
    local @ARGV = ('--version');

    my $pushd = pushd("$dir");

    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture { $cli->run };
    like( $stdout, qr{$App::perlimports::CLI::VERSION}, 'prints version' );
};

# Emulate a user with only a global config file
subtest 'no local config file' => sub {
    my $xdg_config_home = Path::Tiny->tempdir('testconfigXXXXXXXX');
    local $ENV{XDG_CONFIG_HOME} = $xdg_config_home->stringify;

    my $global_config_dir = $xdg_config_home->child('perlimports');
    $global_config_dir->mkpath;
    my $global_config = $global_config_dir->child('perlimports.toml');

    local @ARGV = ( '--create-config-file', $global_config );
    is( App::perlimports::CLI->new->run, '0', 'clean exit code' );
    ok( -e $global_config, 'file created' );

    my $project_dir = Path::Tiny->tempdir('testconfigXXXXXXXX');
    my $pushd       = pushd("$project_dir");

    my $cli = App::perlimports::CLI->new;
    is( $cli->_config_file, $global_config, 'config file found' );

    # Try to recreate config file
    local @ARGV = ( '--create-config-file', $global_config );
    my $exit_code;
    my ( undef, $stderr )
        = capture { $exit_code = App::perlimports::CLI->new->run };
    like(
        $stderr, qr{perlimports.toml already exists},
        'perlimports.toml already exists'
    );
    is( $exit_code, 1, 'non-zero exit code' );
};

subtest 'help' => sub {
    local @ARGV = ('--help');

    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture { $cli->run };
    like( $stdout, qr{filename STR}, 'prints help' );
};

subtest 'verbose help' => sub {
    local @ARGV = ('--verbose-help');

    # Verbose text on $0, which will differ when this is called from
    # script/perlimports
    local $0 = 'script/perlimports';
    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture { $cli->run };
    like(
        $stdout, qr{Create a sample config file},
        'prints help'
    );
};

subtest filter_paths => sub {
    ## no critic (Subroutines::ProtectPrivateSubs)
    my @paths = App::perlimports::CLI::_filter_paths(
        'test-data/filter-paths',
        'test-data/filter-paths/foo.t'
    );
    ## use critic
    eq_or_diff(
        [ sort @paths ],
        [
            'test-data/filter-paths/Foo.pl',
            'test-data/filter-paths/Foo.pm',
            'test-data/filter-paths/foo',
            'test-data/filter-paths/foo.t',
        ]
    );
};

subtest '--filename' => sub {
    my $expected = <<'EOF';
use strict;
use warnings;

use Perl::Critic::Utils qw( $QUOTE );

my %foo = (
    $QUOTE => q{description},
);
EOF

    local @ARGV = (
        '--no-config-file',
        '-f' => 'test-data/var-in-hash-key.pl',
    );
    my $cli = App::perlimports::CLI->new( logger => logger( [] ) );
    my ($stdout) = capture {
        $cli->run;
    };
    is( $stdout, $expected, 'parses filename' );
};

subtest 'invalid --filename' => sub {
    local @ARGV = (
        '--no-config-file',
        '-f' => 'test-data/does-not-exist.pl',
    );
    my $cli = App::perlimports::CLI->new();
    my ( $stdout, $stderr, $exit_code ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT' );
    like(
        $stderr,
        qr{test-data/does-not-exist.pl does not appear to be a file},
        'STDERR contains appropriate error message'
    );
    is( $exit_code, 1, 'exit code is error' );
};

subtest '--lint success' => sub {
    local @ARGV = (
        '--lint',
        '--no-config-file',
        '-f' => 'test-data/lint-success.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is(
        $stdout,
        "test-data/lint-success.pl OK\n",
        'success message on STDOUT'
    );
    is( $stderr, q{}, 'no STDERR on a clean run (GH #163)' );
    is( $exit,   0,   'exit code is success' );
};

subtest '--lint --json success' => sub {
    local @ARGV = (
        '--lint',
        '--json',
        '--no-config-file',
        '-f' => 'test-data/lint-success.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stderr, q{}, 'success message on STDERR' );
    is( $stdout, q{}, 'no STDOUT' );
    is( $exit,   0,   'exit code is success' );
};

subtest '--lint failure import args' => sub {
    local @ARGV = (
        '--lint',
        '--no-config-file',
        '-f' => 'test-data/lint-failure-import-args.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT' );

    my $expected = <<'EOF';
❌ Perl::Critic::Utils (import arguments need tidying) at test-data/lint-failure-import-args.pl line 4
@@ -4 +4 @@
-use Perl::Critic::Utils;
+use Perl::Critic::Utils qw( $QUOTE );

EOF

    is( $stderr, $expected, 'STDERR' );
    is( $exit,   1,         'exit code is error' );
};

subtest '--lint --quiet success' => sub {
    local @ARGV = (
        '--lint',
        '--quiet',
        '--no-config-file',
        '-f' => 'test-data/lint-success.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT with --quiet on a clean run' );
    is( $stderr, q{}, 'no STDERR with --quiet on a clean run' );
    is( $exit,   0,   'exit code is success' );
};

subtest '--lint -q success' => sub {
    local @ARGV = (
        '--lint',
        '-q',
        '--no-config-file',
        '-f' => 'test-data/lint-success.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT with -q on a clean run' );
    is( $stderr, q{}, 'no STDERR with -q on a clean run' );
    is( $exit,   0,   'exit code is success' );
};

subtest '--lint --quiet failure still reports diagnostics' => sub {
    local @ARGV = (
        '--lint',
        '--quiet',
        '--no-config-file',
        '-f' => 'test-data/lint-failure-import-args.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };

    my $expected = <<'EOF';
❌ Perl::Critic::Utils (import arguments need tidying) at test-data/lint-failure-import-args.pl line 4
@@ -4 +4 @@
-use Perl::Critic::Utils;
+use Perl::Critic::Utils qw( $QUOTE );

EOF

    is( $stdout, q{}, 'no STDOUT' );

    # --quiet suppresses the success summary and info/notice noise, but must
    # not swallow genuine failure diagnostics (logged at the error level).
    is( $stderr, $expected, 'failure diagnostics survive --quiet (GH #163)' );
    is( $exit,   1,         'exit code is error' );
};

subtest '--lint --json --quiet failure still reports JSON' => sub {
    local @ARGV = (
        '--lint',
        '--json',
        '--quiet',
        '--no-config-file',
        '-f' => 'test-data/lint-failure-import-args.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };

    is( $stdout, q{}, 'no STDOUT' );
    is( $exit,   1,   'exit code is error' );

    # The machine-readable JSON diagnostic is logged at the error level, so
    # --quiet must not discard it -- a CI consumer needs the payload.
    like(
        $stderr, qr{"diff"},
        'JSON failure diagnostic survives --json --quiet (GH #163)'
    );
    my $decoded;
    is(
        exception { $decoded = decode_json($stderr) },
        undef, 'STDERR is valid JSON'
    ) or diag($stderr);
    is(
        $decoded->{module}, 'Perl::Critic::Utils',
        'JSON reports the offending module'
    );
};

subtest '--lint --json --quiet success' => sub {
    local @ARGV = (
        '--lint',
        '--json',
        '--quiet',
        '--no-config-file',
        '-f' => 'test-data/lint-success.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT with --json --quiet' );
    is( $stderr, q{}, 'no STDERR with --json --quiet' );
    is( $exit,   0,   'exit code is success' );
};

subtest '--lint --log-level=notice noise (control)' => sub {
    local @ARGV = (
        '--lint',
        '--log-level' => 'notice',
        '--no-config-file',
        '-f' => 'test-data/lint-success.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    like(
        $stderr,
        qr{Starting file},
        'notice-level log noise appears without --quiet'
    );
    is( $exit, 0, 'exit code is success' );
};

subtest '--lint --log-level=notice --quiet suppresses log noise' => sub {
    local @ARGV = (
        '--lint',
        '--log-level' => 'notice',
        '--quiet',
        '--no-config-file',
        '-f' => 'test-data/lint-success.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT with --quiet' );
    is(
        $stderr, q{},
        'notice noise and OK line both suppressed by --quiet'
    );
    is( $exit, 0, 'exit code is success' );
};

subtest '--quiet does not silence an explicit --log-filename' => sub {
    my $log = Path::Tiny->tempfile('perlimports-logXXXXXX');
    local @ARGV = (
        '--lint',
        '--log-level' => 'notice',
        '--quiet',
        '--log-filename' => "$log",
        '--no-config-file',
        '-f' => 'test-data/lint-success.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT' );
    is( $stderr, q{}, 'no STDERR (logging is redirected to the file)' );
    like(
        $log->slurp_utf8,
        qr{Starting file},
        'file log keeps notice-level messages despite --quiet'
    );
    is( $exit, 0, 'exit code is success' );
};

subtest '--lint failure unused import' => sub {
    local @ARGV = (
        '--lint',
        '--no-config-file',
        '--no-preserve-unused',
        '-f' => 'test-data/lint-failure-unused-import.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT' );

    my $expected = <<'EOF';
❌ Carp (appears to be unused and should be removed) at test-data/lint-failure-unused-import.pl line 6
@@ -6 +5,0 @@
-use Carp;

EOF

    is( $stderr, $expected, 'STDERR' );
    is( $exit,   1,         'exit code is error' );
};

subtest '--lint failure duplicate import' => sub {
    local @ARGV = (
        '--lint',
        '--no-config-file',
        '--no-preserve-duplicates',
        '-f' => 'test-data/lint-failure-duplicate-import.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT' );

    my $expected = <<'EOF';
❌ Carp (has already been used and should be removed) at test-data/lint-failure-duplicate-import.pl line 7
@@ -7 +6,0 @@
-use Carp;

EOF

    is( $stderr, $expected, 'STDERR' );
    is( $exit,   1,         'exit code is error' );
};

subtest '--lint --json failure duplicate import' => sub {
    local @ARGV = (
        '--lint',
        '--json',
        '--no-config-file',
        '--no-preserve-duplicates',
        '-f' => 'test-data/lint-failure-duplicate-import.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT' );

    my $parsed_stderr = decode_json($stderr);
    eq_or_diff(
        $parsed_stderr,
        {
            diff     => "@@ -7 +6,0 @@\n-use Carp;\n",
            filename => 'test-data/lint-failure-duplicate-import.pl',
            location => {
                end => {
                    column => 9,
                    line   => 7,
                },
                start => {
                    column => 1,
                    line   => 7,
                },
            },
            module => 'Carp',
            reason => 'has already been used and should be removed',
        },
        'lint failure as JSON'
    );
    is( $exit, 1, 'exit code is error' );
};

subtest
    '--lint --json location reports the true column of an indented include'
    => sub {
    local @ARGV = (
        '--lint',
        '--json',
        '--no-config-file',
        '--no-preserve-duplicates',
        '-f' => 'test-data/lint-failure-indented-duplicate.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT' );

    my $parsed_stderr = decode_json($stderr);

    # The redundant `use Carp;` is indented four spaces inside a block, so the
    # start column is 5 (not 1) and the end column is 13 (inclusive).
    eq_or_diff(
        $parsed_stderr->{location},
        {
            start => { line => 8, column => 5 },
            end   => { line => 8, column => 13 },
        },
        'location reflects the indentation of the include'
    );
    is( $exit, 1, 'exit code is error' );
    };

subtest '--sort --json failure reports location and diff' => sub {
    local @ARGV = (
        '--lint',
        '--json',
        '--sort',
        '--no-config-file',
        '-f' => 'test-data/sort-includes.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr, $exit ) = capture {
        $cli->run;
    };
    is( $stdout, q{}, 'no STDOUT' );

    my $parsed_stderr = decode_json($stderr);
    is(
        $parsed_stderr->{reason}, 'includes are not sorted',
        'reason is present'
    );
    is(
        $parsed_stderr->{filename}, 'test-data/sort-includes.pl',
        'filename is present'
    );
    eq_or_diff(
        $parsed_stderr->{location},
        {
            start => { line => 2, column => 1 },
            end   => { line => 4, column => 8 },
        },
        'location spans the changed includes'
    );
    ok( length $parsed_stderr->{diff},    'diff is present and non-empty' );
    ok( !exists $parsed_stderr->{module}, 'module is omitted' );
    is( $exit, 1, 'exit code is error' );
};

subtest '--log-filename' => sub {
    my $expected = <<'EOF';
use strict;
use warnings;

use Perl::Critic::Utils qw( $QUOTE );

my %foo = (
    $QUOTE => q{description},
);
EOF

    my $file = Path::Tiny->tempfile;
    local @ARGV = (
        '-f'             => 'test-data/var-in-hash-key.pl',
        '--log-filename' => "$file",
        '--log-level'    => 'info',
        '--no-config-file',
    );
    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture {
        $cli->run;
    };
    is( $stdout, $expected, 'parses filename' );

    ok( $file->lines, 'something was logged to file' );
};

subtest 'no filename' => sub {
    local @ARGV = ();
    my $cli = App::perlimports::CLI->new;
    my ( undef, $stderr ) = capture {
        $cli->run;
    };
    like(
        $stderr, qr{Mandatory parameter 'filename' missing},
        'filename missing'
    );
};

subtest '--json without --lint' => sub {
    local @ARGV = ( '--json', 'test-data/var-in-hash-key.pl' );
    my $cli = App::perlimports::CLI->new;
    my ( undef, $stderr ) = capture {
        $cli->run;
    };
    like(
        $stderr, qr{--json can only be used with --lint},
        'meaningless --json flag'
    );
};

subtest '--lint with -i' => sub {
    local @ARGV = ( '--lint', '-i', 'test-data/var-in-hash-key.pl' );
    my $cli = App::perlimports::CLI->new;
    my ( undef, $stderr ) = capture {
        $cli->run;
    };
    like(
        $stderr, qr{Cannot lint if inplace edit has been enabled},
        'trying to edit and lint at once'
    );
};

subtest '--ignore-modules' => sub {
    my $expected = <<'EOF';
use strict;
use warnings;

use Perl::Critic::Utils;

my %foo = (
    $QUOTE => q{description},
);
EOF

    local @ARGV = (
        '--no-config-file',
        '--ignore-modules' => 'Perl::Critic::Utils',
        '-f'               => 'test-data/var-in-hash-key.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture { $cli->run };
    is( $stdout, $expected, 'stdout' );
};

subtest '--ignore-modules-pattern' => sub {
    my $expected = <<'EOF';
use strict;
use warnings;

use Perl::Critic::Utils;

my %foo = (
    $QUOTE => q{description},
);
EOF

    local @ARGV = (
        '--no-config-file',
        '--ignore-modules-pattern' => '^Perl::.*',
        '-f'                       => 'test-data/var-in-hash-key.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture { $cli->run };
    is( $stdout, $expected, 'stdout' );
};

subtest '--never-export-modules' => sub {
    my $expected = <<'EOF';
use strict;
use warnings;

use Perl::Critic::Utils ();

my %foo = (
    $QUOTE => q{description},
);
EOF

    local @ARGV = (
        '--no-config-file',
        '--never-export-modules' => 'Perl::Critic::Utils',
        '-f'                     => 'test-data/var-in-hash-key.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture { $cli->run };
    is( $stdout, $expected, 'stdout' );
};

subtest '--no-padding' => sub {
    my $expected = <<'EOF';
use strict;
use warnings;

use Perl::Critic::Utils qw($QUOTE);

my %foo = (
    $QUOTE => q{description},
);
EOF

    local @ARGV = (
        '--no-config-file',
        '--no-padding',
        '-f' => 'test-data/var-in-hash-key.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture { $cli->run };
    is( $stderr, q{},       'no STDERR' );
    is( $stdout, $expected, 'stdout' );
};

subtest '--stdout' => sub {
    my $expected = <<'EOF';
use strict;
use warnings;

use Local::STDOUT ();

BEGIN {
    print "perlimports should trap this";
}
EOF

    local @ARGV = (
        '--no-config-file',
        '--libs' => 'test-data/lib',
        '-f'     => 'test-data/stdout.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture { $cli->run };
    is( $stderr, q{}, 'no STDERR' );

    eq_or_diff( $stdout, $expected );
};

subtest 'range without end' => sub {
    local @ARGV = (
        '--range-begin', 1,
        'test-data/stdout.pl',
    );

    my $expected = 'You must supply both range_begin and range_end';
    my $cli      = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture { $cli->run };
    is( $stdout, q{}, 'no STDOUT' );
    chomp($stderr);

    eq_or_diff( $stderr, $expected );
};

subtest 'range without begin' => sub {
    local @ARGV = (
        '--range-end', 1,
        'test-data/stdout.pl',
    );

    my $expected = 'You must supply both range_begin and range_end';
    my $cli      = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture { $cli->run };
    is( $stdout, q{}, 'no STDOUT' );
    chomp($stderr);

    eq_or_diff( $stderr, $expected );
};

subtest 'range without --read-stdin' => sub {
    local @ARGV = (
        '--range-begin', 1,
        '--range-end',   1,
        'test-data/stdout.pl',
    );

    my $expected = 'You must specify --read-stdin if you provide a range';
    my $cli      = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture { $cli->run };
    is( $stdout, q{}, 'no STDOUT' );
    chomp($stderr);

    eq_or_diff( $stderr, $expected );
};

subtest 'range correct' => sub {
    local @ARGV = (
        '--range-begin', 1,
        '--range-end',   1,
        '--read-stdin',
        'test-data/stdout.pl',
    );

    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture { $cli->run };

    eq_or_diff( $stderr, q{},           'no STDERR' );
    eq_or_diff( $stdout, 'use strict;', 'range returned on STDOUT' );
};

subtest 'entire document range' => sub {
    local @ARGV = (
        '--range-begin', 1,
        '--range-end',   8,
        '--read-stdin',
        'test-data/stdout.pl',
    );

    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture { $cli->run };

    my $expected = <<'EOF';
use strict;
use warnings;


BEGIN {
    print "perlimports should trap this";
}
EOF

    chomp $expected;

    eq_or_diff( $stderr, q{},       'no STDERR' );
    eq_or_diff( $stdout, $expected, 'range returned on STDOUT' );
};

subtest 'STDIN without document range' => sub {
    local @ARGV = (
        '--read-stdin',
        '--filename', 'test-data/stdout.pl',
    );

    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture { $cli->run };

    my $expected = <<'EOF';
use strict;
use warnings;


BEGIN {
    print "perlimports should trap this";
}
EOF

    eq_or_diff( $stderr, q{},       'no STDERR' );
    eq_or_diff( $stdout, $expected, 'range returned on STDOUT' );
};

done_testing();
