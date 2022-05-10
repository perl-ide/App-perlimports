use strict;
use warnings;

use Test::More import => [qw( done_testing is )];
use Test::Needs qw( Perl::Critic::Utils );

use lib 't/lib';
use TestHelper qw( source2pi );

my $source_text = 'use Perl::Critic::Utils;';
my $e           = source2pi( 'test-data/var-in-hash-key.pl', $source_text );

is(
    $e->formatted_ppi_statement,
    'use Perl::Critic::Utils qw( $QUOTE );',
    'var in hash key is found'
);

done_testing();
