#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestHelper qw( doc );
use Test::Fatal qw( exception );
use Test::More import => [ 'done_testing', 'ok' ];

my $source_text = 'use Local::Module::Does::Not::Exist::At::All;';

my ( $doc, $log ) = doc(
    filename  => 'test-data/geo-ip.pl',
    selection => $source_text,
);

$doc->tidied_document;

my $found = grep { qr{Can't locate Local/Module} } @{$log};
ok(
    $found,
    'exception on module not found'
);

done_testing();
