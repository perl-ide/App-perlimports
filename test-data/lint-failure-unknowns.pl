use strict;
use warnings;

use Carp;
use Perl::Critic::Utils qw(:classification);

my %foo = (
    $QUOTE => q{description},
);

sub croaker {
    my @args = @_;
    cluck "seen it" if is_qualified_nam $args[0];
    croak "no way" unless @args == 1;
}

croaker( 7, 11 );

