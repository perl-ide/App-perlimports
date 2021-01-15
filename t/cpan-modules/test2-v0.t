use strict;
use warnings;

use App::perlimports::ExportInspector ();
use Devel::Confess;
use Test::More import => [ 'done_testing', 'ok' ];
use Test::Needs qw( Test2::V0 );

my $ei = App::perlimports::ExportInspector->new( module_name => 'Test2::V0' );

# This used to throw an exception, because we weren't checking if meta()
# returns an object.
ok( !$ei->is_oo_class, 'is not OO class' );

done_testing();
