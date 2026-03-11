#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use PPI::Document              ();
use TestHelper                 qw( logger );
use Test::Differences          qw( eq_or_diff );
use Test::More import => [qw( done_testing is is_deeply subtest )];

subtest 'linting doesnt change found_imports' => sub {
    my @log;

    my $doc = App::perlimports::Document->new(
        lint     => 1,
        filename => 'test-data/doc-imports.pl',
        logger   => logger( \@log ),
    );

    # expected value
    my $original_imports = { Carp => [ 'confess', 'croak' ] };

    is_deeply $doc->found_imports, $original_imports,
        'found_imports before linting as expected';

    my $result = $doc->linter_success;
    is $result, q{}, 'linting failure';

    my $found
        = grep { $_->{message} =~ /import arguments need tidying/ } @log;
    is $found, 2, 'log indicates Carp imports need fixing';

    eq_or_diff $doc->found_imports, { Carp => ['croak'] },
        'and doc found_imports changed in lint mode';
};

subtest 'found_imports edited' => sub {
    my @log;

    my $doc = App::perlimports::Document->new(
        lint     => 0,
        filename => 'test-data/doc-imports.pl',
        logger   => logger( \@log ),
    );

    # expected original and cleaned values
    my $original_imports = { Carp => [ 'confess', 'croak' ] };
    my $clean_imports    = { Carp => ['croak'] };

    is_deeply $doc->found_imports, $original_imports,
        'found_imports before editing as expected';

    my $clean_source = $doc->tidied_document;

    my $found
        = grep { $_->{message} =~ /resetting imports as .use Carp/ } @log;
    is $found, 2, 'log indicates Carp import was fixed';

    is_deeply $doc->found_imports, $clean_imports,
        'doc found_imports changed in edit mode';

    # preserve_duplicates defaulted to 1, so we now have two
    # identical use statements!
    # diag $clean_source;

    # -----------

    @log = ();
    my $ppi_doc = PPI::Document->new( \$clean_source );
    my $cdoc    = App::perlimports::Document->new(
        lint         => 1,
        logger       => logger( \@log ),
        filename     => 'none',
        ppi_document => $ppi_doc,
    );

    is_deeply $cdoc->found_imports, $clean_imports,
        'verified doc imports (with duplicate use statements)';

    is $cdoc->linter_success, 1, 'lint succeeds';

    is_deeply $cdoc->found_imports, $clean_imports,
        'linting does not change doc found_imports';
};

done_testing();

