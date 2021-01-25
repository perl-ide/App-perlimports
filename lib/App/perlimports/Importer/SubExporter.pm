package App::perlimports::Importer::SubExporter;

use strict;
use warnings;

our $VERSION = '0.000001';

use App::perlimports::ExportInspector::Inspection ();
use Class::Inspector                              ();
use List::Util qw( any );
use Symbol::Get ();

sub maybe_get_exports {
    my $module_name = shift;

    my $pkg = 'Local::App::perlimports::imported::' . $module_name;
    my @error;

    local $@ = undef;

    # XXX trap error
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval "package $pkg; use $module_name qw( :default );1;";
    push @error, $@ if $@;
    local $@ = undef;
    ## use critic

    my %default_export = map { $_ => $_ }
        grep { $_ ne 'BEGIN' && $_ !~ m{^__ANON__} && $_ ne 'ISA' }
        Symbol::Get::get_names($pkg);

    # XXX trap error
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval "package $pkg; use $module_name qw( :all );1;";
    push @error, $@ if $@;
    ## use critic

    my %export = map { $_ => $_ }
        grep { $_ ne 'BEGIN' && $_ !~ m{^__ANON__} && $_ ne 'ISA' }
        Symbol::Get::get_names($pkg);

    my $is_moose_type_class;

    # Treat Moose type libraries a bit differently. Importing ArrayRef, for
    # instance, also imports is_ArrayRef and to_ArrayRef (if a coercion)
    # exists. So, let's deal with that here.
    my $private
        = Class::Inspector->methods( $module_name, 'full', 'private' );

    if ( any { $_ eq 'MooseX::Types::Combine::_provided_types' } @{$private} )
    {
        for my $key ( keys %export ) {
            if ( $key =~ m{^(is_|to_)} ) {
                $export{$key} = substr( $key, 3 );
            }
        }
        $is_moose_type_class = 1;
    }

    my $isa;
    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    $isa = [ @{ $pkg . '::ISA' } ];
    use strict;
    ## use critic

    return App::perlimports::ExportInspector::Inspection->new(
        {
            all_exports => \%export,
            @{$isa} ? ( class_isa => $isa ) : (),
            default_exports => \%default_export,
            errors          => \@error,
            $is_moose_type_class ? ( is_moose_type_class => 1 ) : (),
            is_sub_exporter =>
                ( !!keys %export || !!keys %default_export || 0 ),
        }
    );
}

1;

# ABSTRACT: A hack to try to figure out what a Sub::Exporter module exports

=pod

=head1 DESCRIPTION

L<Sub::Exporter> doesn't use C<@EXPORT> or C<@EXPORT_OK>, but it does create an
import tag of C<:all>, if the user doesn't define it. We try to use this import
tag to find all of the functions which a module that uses Sub::Exporter might
export.

=head2 maybe_get_exports

    use App::perlimports::Importer::SubExporter ();

    my ( $exports, $attr, $error )
        = App::perlimports::Importer::SubExporter::maybe_get_exports(
        $module_name );

=cut
