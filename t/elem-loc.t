use strict;
use warnings;

use lib 't/lib';

use Cpanel::JSON::XS qw( decode_json );
use TestHelper       qw( doc );
use Test::More import => [qw( done_testing is is_deeply subtest $TODO )];
use Test::Needs {
    'Cpanel::JSON::XS' => 4.19,
    'Getopt::Long'     => 2.40,
    'LWP::UserAgent'   => 5.00,
};
use App::perlimports::Document ();

subtest 'json linting gets correct locations' => sub {
    my ( $doc, $log ) = doc(
        filename      => 'test-data/elem-loc.pl',
        lint_unknowns => 1,
        json          => 1,
    );

    # prior to processing:
    my $includes = $doc->includes;

    my ($firstinclude) = $includes->[0];
    is_deeply App::perlimports::Document::_elem_loc($firstinclude), {
        start => { line => 5, column => 3 },
        end   => { line => 5, column => 44 },
        },
        'first include stm elem_loc';

    my ($longinclude) = grep { $_->content =~ /Test::Script/ } @$includes;
    is_deeply $longinclude->location, [ 6, 1, 1, 6, 'test-data/elem-loc.pl' ],
        'include stm location (before)';
    is_deeply App::perlimports::Document::_elem_loc($longinclude), {
        start => { line => 6, column => 1 },
        end   => { line => 7, column => 41 },
        },
        'long include stm elem_loc';

    #p $longinclude;

    my ($lastinclude) = $includes->[-1];
    is_deeply App::perlimports::Document::_elem_loc($lastinclude), {
        start => { line => 8, column => 1 },
        end   => { line => 8, column => 27 },
        },
        'last include stm elem_loc';

    is $doc->linter_success, q{}, 'linting failed';

    my @errs = grep { $_->{level} eq 'error' } @$log;
    $_->{message} = decode_json( $_->{message} ) for @errs;

    # the first error message is about the Cpanel::JSON::XS include
    my $found = shift @errs;
    is $found->{message}{module}, 'Cpanel::JSON::XS',
        'found the Cpanel::JSON::XS log';
    is_deeply $found->{message}{location}, {
        start => { line => 5, column => 3 },
        end   => { line => 5, column => 44 },
        },
        'json log gets column of indented statement correct';

    # the next error message is about the Test::Script include
    $found = shift @errs;
    is $found->{message}{module}, 'Test::Script', 'found the Test:Script log';
    is_deeply $found->{message}{location}, {
        start => { line => 6, column => 1 },
        end   => { line => 7, column => 41 },
        },
        'json log gets location of multiline statement correct';

    # the final error message is about the unknown 'qv' function
    $found = pop @errs;
    is $found->{message}{name}, 'qv', 'found the qv log';
    is_deeply $found->{message}{location}, {
        start => { line => 3, column => 29 },
        end   => { line => 3, column => 30 },
        },
        'json log gets location of unknown function correct';

    # now these are rewritten includes...
    ( $firstinclude, $longinclude, $lastinclude ) = @{ $doc->includes };

    is_deeply $firstinclude->location,
        [ 5, 3, 3, 5, 'test-data/elem-loc.pl' ],
        'first include stm location (after)';
    is_deeply App::perlimports::Document::_elem_loc($firstinclude), {
        start => { line => 5, column => 3 },
        end   => { line => 5, column => 46 },
        },
        'first include stm elem_loc';
    is_deeply $longinclude->location, [ 6, 1, 1, 6, 'test-data/elem-loc.pl' ],
        'long include stm location (after)';
    is_deeply App::perlimports::Document::_elem_loc($longinclude), {
        start => { line => 6,  column => 1 },
        end   => { line => 11, column => 2 },
        },
        'long include stm elem_loc';
TODO: {
        local $TODO = 'properly flush_locations and rebuild them';
        is_deeply $lastinclude->location,
            [ 12, 1, 1, 12, 'test-data/elem-loc.pl' ],
            'last include stm location (after)';
        is_deeply App::perlimports::Document::_elem_loc($lastinclude), {
            start => { line => 12, column => 1 },
            end   => { line => 12, column => 39 },
            },
            'last include stm elem_loc';
    }
};

done_testing();

