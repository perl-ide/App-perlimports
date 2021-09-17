use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Annotations ();
use PPI::Document                 ();
use TestHelper qw( doc );
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

subtest 'mixed' => sub {
    my $doc = PPI::Document->new( 'test-data/annotation.pl', readonly => 1, );

    die 'could not parse' unless $doc;

    my $anno = App::perlimports::Annotations->new( ppi_document => $doc );

    my $includes = $doc->find('PPI::Statement::Include');

    is( $includes->[0]->module, 'strict' );
    ok( !$anno->is_ignored( $includes->[0] ), 'pragma not ignored' );

    is( $includes->[1]->module, 'warnings' );
    ok( !$anno->is_ignored( $includes->[1] ), 'pragma not ignored' );

    is( $includes->[2]->module, 'Carp' );
    ok( $anno->is_ignored( $includes->[2] ), 'Carp is ignored' );

    is( $includes->[3]->module, 'POSIX' );
    ok( !$anno->is_ignored( $includes->[3] ), 'POSIX is not ignored' );

    is( $includes->[4]->module, 'Cwd' );
    ok( $anno->is_ignored( $includes->[4] ), 'Cwd is ignored' );

    is( $includes->[5]->module, 'Digest' );
    ok( $anno->is_ignored( $includes->[5] ), 'Digest is ignored' );

    is( $includes->[6]->module, 'Encode' );
    ok( !$anno->is_ignored( $includes->[6] ), 'Encode is not ignored' );
};

subtest 'all' => sub {
    my $doc = PPI::Document->new(
        'test-data/annotate-everything.pl',
        readonly => 1,
    );

    die 'could not parse' unless $doc;

    my $anno = App::perlimports::Annotations->new( ppi_document => $doc );

    my $includes = $doc->find('PPI::Statement::Include');

    for my $include ( @{$includes} ) {
        ok( $anno->is_ignored($include), "$include ignored" );
    }
};

subtest 'via Document.pm' => sub {
    my ($doc)
        = doc( filename => 'test-data/annotation.pl', preserve_unused => 0, );
    my $expected = <<'EOF';
use strict;
use warnings;

use Carp;    ## no perlimports

use POSIX qw( sprintf );

## no perlimports
use Cwd;
use Digest;
## use perlimports

use Encode qw( decode encode );
use FindBin; # Reasons ## no perlimports

print decode(
    'utf8',
    sprintf(
        'hey %s', encode( 'utf8', 'Sofia Margareta Götschenhjelm-Helin' )
    )
);
EOF

    is( $doc->tidied_document, $expected, 'tidied_document' );
};

done_testing();
