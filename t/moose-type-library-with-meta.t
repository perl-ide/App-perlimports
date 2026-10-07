#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use TestHelper qw( doc inspector );
use Test::More import => [qw( done_testing is ok )];
use Test::Needs qw( MooseX::Types );

# A MooseX::Types type library which also has a Moose metaclass, as type
# libraries did with MooseX::Types 0.50. See GH#202.
my ($ei) = inspector('Local::MooseTypeLibraryWithMeta');

ok( $ei->uses_moose,          'library has a Moose metaclass' );
ok( $ei->is_moose_type_class, 'library is a Moose type class' );
ok( !$ei->is_moose_class,     'library is not a Moose class' );

my ($doc) = doc(
    filename  => 'test-data/moose-type-library-with-meta.pl',
    selection => 'use Local::MooseTypeLibraryWithMeta;',
);

is(
    $doc->tidied_document,
    'use Local::MooseTypeLibraryWithMeta qw( TheType );',
    'missing type import is added'
);

done_testing;
