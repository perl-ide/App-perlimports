use strict;
use warnings;

use Perl::Critic::Utils qw( $QUOTE );

my $foo = <<"EOT";
one $QUOTE two
EOT

my $bar = <<'EOT';
one $DQUOTE two
EOT
