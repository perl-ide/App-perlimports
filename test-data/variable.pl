use strict;
use warnings;

use Getopt::Long qw( $REQUIRE_ORDER $RETURN_IN_ORDER );

print ${RETURN_IN_ORDER};

my $code = <<"EOT";
${REQUIRE_ORDER}
EOT

my $more = <<'EOT';
${PERMUTE}
EOT
