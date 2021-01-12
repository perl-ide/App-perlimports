#!/usr/bin/env perl

use strict;
use warnings;

require LWP::UserAgent;

if ( $ENV{FOO} ) {
    require WWW::Mechanize;
}

require Carp if $ENV{BAR};

require List::Util;

require Time::Local if $^O eq 'MacOS';

require Cwd;

my @foo = List::Util::any { $_ > 3 } ( 0..4 );
my $bar = any ();
sub any {
    return 1;
}
