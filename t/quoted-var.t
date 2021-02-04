#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use App::perlimports ();
use Path::Tiny qw( path );
use TestHelper qw( source2pi );
use Test::More import => [ 'done_testing', 'is', 'ok' ];

my $filename = 'test-data/quoted-var.pl';
my $content  = path($filename)->slurp;
my $doc      = PPI::Document->new( \$content );

my $includes = $doc->find(
    sub {
        $_[1]->isa('PPI::Statement::Include');
    }
) || [];

my $e = source2pi(
    $filename,
    undef,
    { include => $includes->[2] },
);

ok( !$e->_is_ignored, 'is not ignored' );
is(
    $e->formatted_ppi_statement,
    q{use IO::Uncompress::Gunzip qw( $GunzipError );},
    'var is detected inside of quotes'
);

done_testing();
