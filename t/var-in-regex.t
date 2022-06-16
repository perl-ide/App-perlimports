use strict;
use warnings;

use lib 't/lib';

use Test::More import => [qw( done_testing is )];
use TestHelper  qw( source2pi );
use Test::Needs qw( Perl::Critic::Utils );

my $source_text = 'use Perl::Critic::Utils qw( $BACKTICK $PERIOD );';
my $include     = source2pi( 'test-data/var-in-regex.pl', $source_text );

is(
    $include->formatted_ppi_statement,
    $source_text,
    'exported var in regex is detected'
);

done_testing();
