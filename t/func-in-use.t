#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc source2pi );
use Test::More import => [qw( done_testing is subtest )];
use Test::Needs;

subtest 'catdir' => sub {
    test_needs { 'File::Spec::Functions' => '3.75' };
    my $source_text = 'use File::Spec::Functions;';
    my $e           = source2pi( 'test-data/func-in-use.pl', $source_text );

    is(
        $e->formatted_ppi_statement,
        'use File::Spec::Functions qw( catdir );',
        'func in use statement is detected'
    );
};

subtest 'Mojo::File' => sub {
    test_needs { Mojolicious => '8.25' };
    my ($doc) = doc(
        filename  => 'test-data/func-in-use-2.pl',
        selection => 'use Mojo::File;',
    );

    is(
        $doc->tidied_document,
        'use Mojo::File qw( curfile );',
        'func in use is recognized'
    );
};

done_testing();
