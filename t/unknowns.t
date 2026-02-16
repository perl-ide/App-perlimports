#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use TestHelper                 qw( logger );
use Test::More import => [qw( done_testing is is_deeply isa_ok subtest )];

subtest 'unknown function without lint_unknowns' => sub {
    my @log;

    my $doc = App::perlimports::Document->new(
        lint     => 1,
        filename => 'test-data/use-constant.pm',
        logger   => logger( \@log ),
    );

    # process the doc so that found_imports is updated to include
    # unimported but found symbols: confess, timelocal
    is $doc->linter_success, q{}, 'test code has lint issues';

    # unknown list excludes the qualified name 'Scalar::Util::blessed', and
    # the found (but omitted) imports 'confess' and 'timelocal'
    my @unknown1 = @{ $doc->unknown_words };    # PPI:Token:Word
    is scalar(@unknown1), 1, 'found only 1 unknown word';
    my $word = shift @unknown1;

    isa_ok( $word, 'PPI::Token::Word', 'unknown word' );
    is $word->content, 'qv', 'unknown word is "qv"';
    is_deeply $word->location,
        [ 6, 29, 29, 6, 'test-data/use-constant.pm' ],
        'unknown word "qv" location';

    my $found = grep { $_->{message} =~ /qv/ } @log;
    is $found, 0, 'no logs mention the unknown symbol';

    $found = grep { $_->{message} =~ /Unknown function/ } @log;
    is $found, 0, 'no logs mention unknown function';
};

subtest 'misspelled function with lint_unknowns' => sub {
    my @log;

    my $doc = App::perlimports::Document->new(
        lint_unknowns => 1,    # implies lint => 1
        filename      => 'test-data/lint-failure-unknowns.pl',
        logger        => logger( \@log ),
    );

    is $doc->linter_success, q{}, 'test code has lint issues';

    my @unknown = @{ $doc->unknown_words };    # PPI:Token:Word
    my @words
        = map { $_->isa('PPI::Token::Quote') ? $_->string : $_->content }
        @unknown;

    # unknowns do _not_ include the identified (omitted) imports:
    # "cluck", "$QUOTE"
    is_deeply \@words, ['is_qualified_nam'],
        'found one unknown symbol (none of the found ones)';

    my ($found)
        = grep { $_->{message} =~ /Unknown function .is_qualified_nam/ } @log;
    is $found && $found->{level}, 'error',
        'lint-level log about the unknown symbol exists';
};

done_testing();

