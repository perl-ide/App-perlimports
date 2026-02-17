#!perl

use strict;
use warnings;
use feature 'say';

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use TestHelper                 qw( logger );
use Test::More import => [qw( done_testing is is_deeply ok subtest )];

subtest 'constants parsed' => sub {
    my @log;

    my $doc = App::perlimports::Document->new(
        lint     => 1,
        filename => 'test-data/use-constant.pm',
        logger   => logger( \@log ),
    );

    is $doc->linter_success, q{}, 'test code has lint issues';

    my @possible = $doc->possibly_imported_tokens;

    my $found = $doc->_ppi_selection->find(
        sub {
            $_[1]->isa('PPI::Statement::Package')
                && $_[1]->file_scoped;
        }
    ) || [];
    my ($packname) = map { $_->namespace } @$found;
    ok $packname, "package name $packname detected";
    $found = grep { $_ eq $packname } @possible;
    is $found, 0, 'package name is excluded from possible_imports';
    $found = grep { $_ eq 'package' } @possible;
    is $found, 0, 'keyword "package" also excluded';
    $found = grep { $_ eq 'use' } @possible;
    is $found, 0, 'keyword "use" also excluded';

    my @cnames
        = qw(FIRST_IDX IDX_FORMAT IDX_SEP IDX_SEP_RE IDX_STR IDX_UTIME);
    my @found = sort $doc->all_constants;
    is_deeply \@found, \@cnames, 'parsed all 6 constants';

    # find all "possible imported" tokens that match any of the constants
    my %cnames  = map  { $_ => 1 } @cnames;
    my @matches = grep { $cnames{"$_"} } @possible;
    is scalar(@matches), 0,
        'constants are entirely excluded from possible_imports';
};

done_testing();

