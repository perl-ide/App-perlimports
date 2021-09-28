package App::perlimports::Sandbox;

use strict;
use warnings;

our $VERSION = '0.000023';

use Data::UUID ();

{
    my $du = Data::UUID->new;

    sub pkg_for {
        my $module_name = shift;
        my $unique      = 'A' . $du->create_str;
        $unique =~ s{-}{}g;

        return sprintf(
            'Local::%s::%s',
            $module_name,
            $unique
        );
    }
}

1;

# ABSTRACT: Internal Tools for perlimports

=head1 pkg_for( $string )

Returns a random module/package name, which can be used to eval arbitrary code.
Requires the name of the module which will be imported into the package to be
created.