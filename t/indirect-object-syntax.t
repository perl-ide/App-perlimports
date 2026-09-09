use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use TestHelper qw( doc );
use Test::More import => [qw( done_testing ok )];

my ( $doc, $log ) = doc(
    filename        => 'test-data/indirect-object-syntax.pl',
    preserve_unused => 0,
    tidy_whitespace => 0,
);

ok(
    $doc->_is_used_fully_qualified('File'),
    'indirect object syntax: new File $path, $data'
);
ok(
    $doc->_is_used_fully_qualified('Database'),
    'indirect object syntax: connect Database $dsn'
);
ok(
    !$doc->_is_used_fully_qualified('Unused'),
    'use statement is not treated as indirect object usage'
);
ok(
    !$doc->_is_used_fully_qualified('Widget'),
    'sub declaration is not treated as indirect object usage'
);

done_testing;
