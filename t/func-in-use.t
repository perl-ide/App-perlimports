use strict;
use warnings;

use lib 't/lib';

use App::perlimports::Document ();
use Test::More import => [ 'done_testing', 'is' ];
use Test::Needs qw( File::Spec::Functions Mojo );
use TestHelper qw( source2pi );

my $source_text = 'use File::Spec::Functions;';
my $e           = source2pi( 'test-data/func-in-use.pl', $source_text );

is(
    $e->formatted_ppi_statement,
    'use File::Spec::Functions qw( catdir );',
    'func in use statement is detected'
);

my $doc = App::perlimports::Document->new(
    filename  => 'test-data/func-in-use-2.pl',
    selection => 'use Mojo::File;',
);

is(
    $doc->tidied_document,
    'use Mojo::File qw( curfile );',
    'func in use is recognized'
);

done_testing();
