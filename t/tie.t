use strict;
use warnings;

use lib 't/lib';

use Path::Tiny qw( path );
use TestHelper qw( doc );
use Test::More import => [qw( done_testing is $TODO )];

my $filename = 'test-data/tie.pl';
my ($doc) = doc(
    filename        => $filename,
    preserve_unused => 0,
);

TODO: {
    local $TODO = 'Cannot yet see packages used by tie';
    is( $doc->tidied_document, path($filename)->slurp, 'tie observed' );
}

done_testing();
