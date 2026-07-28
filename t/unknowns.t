#!perl

use strict;
use warnings;

use lib 'test-data/lib', 't/lib';

use App::perlimports::Document ();
use TestHelper                 qw( logger );
use Cpanel::JSON::XS           qw( decode_json );
use Test::More import =>
    [qw( done_testing is is_deeply isa_ok like subtest )];

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
    like $found->{message}, qr/line 13/,
        '...and it references correct line number';
};

subtest 'lint_unknowns with json mode' => sub {
    my @log;

    my $doc = App::perlimports::Document->new(
        lint_unknowns => 1,    # implies lint => 1
        json          => 1,
        filename      => 'test-data/lint-failure-unknowns.pl',
        logger        => logger( \@log ),
    );

    is $doc->linter_success, q{}, 'test code has lint issues';

    # 'cluck' and '$QUOTE' are no longer unknown, because we found
    # them when processing the includes!

    my @unknown = @{ $doc->unknown_words };    # PPI:Token:Word
    is scalar(@unknown), 1, 'found only 1 unknown word';
    my $word = shift @unknown;

    isa_ok( $word, 'PPI::Token::Word', 'unknown word' );
    is $word->content, 'is_qualified_nam',
        'unknown word is "is_qualified_nam"';
    is_deeply $word->location,
        [ 13, 24, 24, 13, 'test-data/lint-failure-unknowns.pl' ],
        'unknown word "is_qualified_nam" location';

    my ($found)
        = grep { $_->{message} =~ /Unknown function/ } @log;
    is $found && $found->{level}, 'error',
        'lint-level log about the unknown symbol exists';
    my $hash = decode_json( $found->{message} );
    is_deeply $hash, {
        filename  => 'test-data/lint-failure-unknowns.pl',
        reason    => 'Unknown function',
        name      => 'is_qualified_nam',
        statement => 'cluck "seen it" if is_qualified_nam $args[0];',
        location  => {
            start => { line => 13, column => 24 },
            end   => { line => 13, column => 39 }
        },
        },
        'json log message as expected';
};

done_testing();

