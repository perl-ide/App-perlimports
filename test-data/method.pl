#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::Status;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
my $res = $ua->get('https://metacpan.org');

print 'ok' if $res->is_success;
