#!perl

use strict;
use warnings;
use feature 'say';

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use TestHelper                 qw( logger );
use Test::More import => [qw( done_testing is is_deeply subtest )];

subtest 'constants parsed' => sub {
    my @log;

    my $doc = App::perlimports::Document->new(
        lint     => 1,
        filename => 'test-data/use-constant.pm',
        logger   => logger( \@log ),
    );

    is $doc->linter_success, q{}, 'test code has lint';

    my @cnames
        = qw(FIRST_IDX IDX_FORMAT IDX_SEP IDX_SEP_RE IDX_STR IDX_UTIME);
    my @found = sort $doc->all_constants;
    is_deeply \@found, \@cnames, 'parsed all 6 constants';

    # find all "possible imported" tokens that match any of the constants
    my %cnames   = map { $_ => 1 } @cnames;
    my $possible = $doc->possible_imports;              # tokens
    my @matches  = grep { $cnames{"$_"} } @$possible;
    is scalar(@matches), 0,
        'constants are entirely excluded from possible_imports';
};

done_testing();

