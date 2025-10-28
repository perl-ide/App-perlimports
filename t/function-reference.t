use strict;
use warnings;

use lib 't/lib', 'test-data/lib';

use Test::Differences qw( eq_or_diff );
use TestHelper        qw( doc );
use Test::More import => [qw( diag done_testing ok )];
use Test::Needs qw( Cpanel::JSON::XS );

my ( $doc, $log ) = doc(
    filename        => 'test-data/function-reference.pl',
    preserve_unused => 0,
);

ok(
    $doc->_is_used_fully_qualified('Cpanel::JSON::XS'),
    'find Cpanel::JSON::XS via function reference'
);

my $expected = <<'EOF';
use strict;
use warnings;

use Cpanel::JSON::XS ();

my $true_ref = \&Cpanel::JSON::XS::true;
my $false_ref = \&Cpanel::JSON::XS::false;
EOF

eq_or_diff(
    $doc->tidied_document, $expected,
    'function reference keeps module'
) || do { require Data::Dumper; diag Data::Dumper::Dumper($log); };

done_testing;
