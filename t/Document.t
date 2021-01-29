use strict;
use warnings;

use App::perlimports::Document ();
use Test::More;

my $doc = App::perlimports::Document->new(
    filename => 'test-data/original-imports.pl' );

ok( $doc->inspector_for('Carp'),         'Carp' );
ok( $doc->inspector_for('Data::Dumper'), 'Data::Dumper' );
ok( $doc->inspector_for('POSIX'),        'POSIX' );

done_testing();
