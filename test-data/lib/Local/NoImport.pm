package Local::NoImport;

use strict;
use warnings;

our $VERSION = '1.00';

# Intentionally defines no import() method and no exports. Calling
# `use Local::NoImport qw( ... )` therefore makes Perl emit its "Attempt to
# call undefined/missing import method" diagnostic. t/Sandbox.t uses this to
# verify App::perlimports::Sandbox suppresses that trial-load noise, whatever
# wording the running Perl uses for the warning (see GH #181).

1;
