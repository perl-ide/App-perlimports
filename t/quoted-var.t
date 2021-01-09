use strict;
use warnings;

use App::perlimports ();
use Path::Tiny qw( path );
use Test::More import => [ 'done_testing', 'is', 'ok', 'subtest' ];

my $filename = 'test-data/quoted-var.pl';
my $content  = path($filename)->slurp;
my $doc      = PPI::Document->new( \$content );

my $includes = $doc->find(
    sub {
        $_[1]->isa('PPI::Statement::Include');
    }
) || [];

my $e = App::perlimports->new(
    filename => $filename,
    include  => $includes->[2],
);

ok( !$e->_is_ignored, 'is not ignored' );
is(
    $e->formatted_ppi_statement,
    q{use IO::Uncompress::Gunzip qw( $GunzipError );},
    'var is detected inside of quotes'
);

done_testing();
