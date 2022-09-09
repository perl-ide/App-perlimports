#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::CLI ();
use Capture::Tiny         qw( capture );
use File::pushd           qw( pushd );
use Path::Tiny            ();
use TestHelper            qw( logger );
use Test::Differences     qw( eq_or_diff );
use Test::Fatal           qw( exception );
use Test::More import => [qw( done_testing is like ok subtest )];
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
    use DDP;

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
    my $cli   = App::perlimports::CLI->new;
    my @paths = sort $cli->_filter_paths(
        'test-data/filter-paths',
        'test-data/filter-paths/foo.t'
    );
    eq_or_diff(
        \@paths,
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
        $stderr,
        "test-data/lint-success.pl OK\n",
        'success message on STDERR'
    );
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
❌ Perl::Critic::Utils (import arguments have changed) at test-data/lint-failure-import-args.pl line 4
@@ -4 +4 @@
-use Perl::Critic::Utils;
+use Perl::Critic::Utils qw( $QUOTE );

EOF

    is( $stderr, $expected, 'STDERR' );
    is( $exit,   1,         'exit code is error' );
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

    eq_or_diff( $stdout, $expected );
};

done_testing();
