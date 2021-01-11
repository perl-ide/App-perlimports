package App::perlimports::Importer::SubExporter;

use strict;
use warnings;

use Class::Inspector ();
use List::Util qw( any );
use Symbol::Get ();

sub maybe_get_all_exports {
    my $module_name = shift;

    my $pkg = 'Local::App::perlimports::imported::' . $module_name;
    my $error;

    # XXX trap error
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval "package $pkg; use $module_name qw( :all );1;";
    $error = $@;
    ## use critic

    my %export = map { $_ => $_ }
        grep { $_ ne 'BEGIN' } Symbol::Get::get_names($pkg);

    # Treat Moose type libraries a bit differently. Importing ArrayRef, for
    # instance, also imports is_ArrayRef and to_ArrayRef (if a coercion)
    # exists. So, let's deal with that here.
    if (
        any { $_ eq 'MooseX::Types::Combine::_provided_types' }
        @{ Class::Inspector->methods( $module_name, 'full', 'private' ) || []
        }
    ) {
        for my $key ( keys %export ) {
            if ( $key =~ m{(is_|to_)} ) {
                $export{$key} = substr( $key, 3 );
            }
        }
    }

    return ( \%export, $error );
}

1;

# ABSTRACT: A hack to try to figure out what a Sub::Exporter module exports

=pod

=head1 DESCRIPTION

L<Sub::Exporter> doesn't use C<@EXPORT> or C<@EXPORT_OK>, but it does create an
import tag of C<:all>, if the user doesn't define it. We try to use this import
tag to find all of the functions which a module that uses Sub::Exporter might
export.

=head2 maybe_get_all_exports

    use App::perlimports::Importer::SubExporter ();

    my ( $exports, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_all_exports(
        $module_name );

=cut
