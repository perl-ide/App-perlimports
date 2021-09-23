use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::CLI ();
use Capture::Tiny qw( capture );
use Path::Tiny ();
use TestHelper qw( logger );
use Test::Differences qw( eq_or_diff );
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];
use Test::Needs qw( Perl::Critic::Utils );

subtest '--filename' => sub {
    my $expected = <<'EOF';
use strict;
use warnings;

use Perl::Critic::Utils qw( $QUOTE );

my %foo = (
    $QUOTE => q{description},
);
EOF

    local @ARGV = ( '-f', 'test-data/var-in-hash-key.pl', );
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
        '-f',             'test-data/var-in-hash-key.pl',
        '--log-filename', $file,
        '--log-level',    'info',
    );
    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture {
        $cli->run;
    };
    is( $stdout, $expected, 'parses filename' );

    ok( $file->lines, 'something was logged to file' );
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
        '--ignore-modules',
        'Perl::Critic::Utils',
        '-f',
        'test-data/var-in-hash-key.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture {
        $cli->run;
    };
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
        '--ignore-modules-pattern',
        '^Perl::.*',
        '-f',
        'test-data/var-in-hash-key.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture {
        $cli->run;
    };
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
        '--never-export-modules',
        'Perl::Critic::Utils',
        '-f',
        'test-data/var-in-hash-key.pl',
    );
    my $cli = App::perlimports::CLI->new;
    my ($stdout) = capture {
        $cli->run;
    };
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

    local @ARGV = ( '--no-padding', '-f', 'test-data/var-in-hash-key.pl', );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture {
        $cli->run;
    };
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

    local @ARGV = ( '-f', 'test-data/stdout.pl', );
    my $cli = App::perlimports::CLI->new;
    my ( $stdout, $stderr ) = capture {
        $cli->run;
    };

    eq_or_diff( $stdout, $expected );
};

done_testing();
