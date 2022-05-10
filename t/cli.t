use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::CLI ();
use Capture::Tiny qw( capture );
use File::pushd qw( pushd );
use Path::Tiny ();
use TestHelper qw( logger );
use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( diag done_testing is like ok subtest )];
use Test::Needs qw( Perl::Critic::Utils );

# Emulate a user with no local or global config file
subtest 'no config file' => sub {
    my $dir = Path::Tiny->tempdir("testconfigXXXXXXXX");
    local $ENV{XDG_CONFIG_HOME} = "$dir";
    local @ARGV = ('--version');

    my $pushd = pushd("$dir");

    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture { $cli->run };
    like( $stdout, qr{$App::perlimports::CLI::VERSION}, 'prints version' );
};

# Emulate a user with only a global config file
subtest 'no config file' => sub {
    my $xdg_config_home = Path::Tiny->tempdir('testconfigXXXXXXXX');
    local $ENV{XDG_CONFIG_HOME} = "$xdg_config_home";

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
        $stdout, qr{We can also make this slightly shorter},
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
    local @ARGV;
    my $cli = App::perlimports::CLI->new;
    my ( undef, $stderr ) = capture {
        $cli->run;
    };
    like( $stderr, qr{Mandatory parameter 'filename' missing} );
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
    is( $stdout, $expected, );
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
    is( $stdout, $expected, );
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
    is( $stdout, $expected );
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
    is( $stdout, $expected );
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
    diag $stderr;
};

done_testing();
