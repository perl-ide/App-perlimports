package Local::MooseTypeLibraryWithMeta;

use strict;
use warnings;

use Moose ();
use MooseX::Types -declare => ['TheType'];
use MooseX::Types::Moose qw( Str );

subtype TheType, as Str;

# MooseX::Types 0.50 did "use Moose" in MooseX::Types and MooseX::Types::Base,
# so type libraries ended up with a Moose metaclass. Initialize one explicitly
# so that we can test this behaviour regardless of the installed version.
Moose::Meta::Class->initialize(__PACKAGE__);

1;
