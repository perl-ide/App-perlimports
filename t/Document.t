#!perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing ok )];

my ($doc) = doc( filename => 'test-data/original-imports.pl' );

ok( $doc->inspector_for('Carp'),         'Carp' );
ok( $doc->inspector_for('Data::Dumper'), 'Data::Dumper' );
ok( $doc->inspector_for('POSIX'),        'POSIX' );

done_testing();
