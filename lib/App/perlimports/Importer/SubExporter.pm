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
    my $logger      = shift;

    die 'logger required' unless $logger;

    my @error;
    my @warning;

    my $implicit_exports
        = _exports_for_tag( $module_name, 'default', $logger );

    my $isa              = _isa_for_module( $module_name, 'default' );
    my $explicit_exports = _exports_for_tag( $module_name, 'all', $logger );

    # Are import tags unsupported?
    ($implicit_exports) = _exports_for_tag( $module_name, undef, $logger );

    my $is_moose_type_class;

    # Treat Moose type libraries a bit differently. Importing ArrayRef, for
    # instance, also imports is_ArrayRef and to_ArrayRef (if a coercion)
    # exists. So, let's deal with that here.
    my $private
        = Class::Inspector->methods( $module_name, 'full', 'private' );

    if ( any { $_ eq 'MooseX::Types::Combine::_provided_types' } @{$private} )
    {
        for my $key ( keys %$explicit_exports ) {
            if ( $key =~ m{^(is_|to_)} ) {
                $explicit_exports->{$key} = substr( $key, 3 );
            }
        }
        for my $key ( keys %$implicit_exports ) {
            if ( $key =~ m{^(is_|to_)} ) {
                $implicit_exports->{$key} = substr( $key, 3 );
            }
        }
        $is_moose_type_class = 1;
    }

    my $is_exporter     = 0;
    my $is_sub_exporter = 0;

    # https://metacpan.org/source/TODDR/Exporter-5.74/lib/Exporter/Heavy.pm#L94
    $is_exporter = any { $_ =~ m{is not defined in .*::EXPORT_TAGS} } @error;

    if (   !$is_exporter
        && !scalar @error
        && ( keys %$implicit_exports || keys %$explicit_exports ) ) {
        $is_sub_exporter = 1;
    }

    return App::perlimports::ExportInspector::Inspection->new(
        {
            @{$isa} ? ( class_isa => $isa ) : (),
            explicit_exports => $explicit_exports ? $explicit_exports : {},
            implicit_exports => $implicit_exports ? $implicit_exports : {},
            inspected_by     => __PACKAGE__,
            is_exporter      => $is_exporter,
            $is_moose_type_class ? ( _is_moose_type_class => 1 ) : (),
            is_sub_exporter => $is_sub_exporter,
            logger          => $logger,
        }
    );
}

sub _exports_for_tag {
    my $module_name = shift;
    my $tag         = shift;
    my $logger      = shift;

    my $pkg = _pkg_for_tag( $module_name, $tag );

    my $use_statement
        = $tag ? "use $module_name qw( :$tag );" : "use $module_name;";

    # If you're importing Moose into a namespace and following that with an
    # import of namespace::autoclean, you may find that symbols like "after"
    # and "around" are no longer found.
    #
    # We log available symbols inside the BEGIN block in order to defeat
    # namespace::autoclean, which removes symbols from the stash after
    # compilation but before runtime. Thanks to Florian Ragwizt for the tip and
    # the preceding explanation.

    my $to_eval = <<"EOF";
package $pkg;

use Symbol::Get;
$use_statement;
our \@__EXPORTABLES;

BEGIN {
    \@__EXPORTABLES = Symbol::Get::get_names();
}
1;
EOF

    my $logger_cb = sub {
        my $msg = shift;
        $logger->info(
            sprintf(
                'eval %s in %s: %s',
                $pkg,
                __PACKAGE__,
                $msg,
            )
        );
    };

    local $SIG{__WARN__} = $logger_cb;

    local $@;
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval $to_eval;

    if ($@) {
        $logger_cb->($@);
    }

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my %export = map { $_ => $_ }
        grep { $_ !~ m{(?:BEGIN|ISA|__EXPORTABLES)} && $_ !~ m{^__ANON__} }
        @{ $pkg . '::__EXPORTABLES' };
    use strict;
    ## use critic

    return \%export;
}

sub _isa_for_module {
    my $module_name = shift;
    my $tag         = shift;

    my $pkg = _pkg_for_tag( $module_name, $tag );

    my $isa;
    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    $isa = [ @{ $pkg . '::ISA' } ];
    use strict;
    ## use critic

    return $isa;
}

sub _pkg_for_tag {
    my $module_name = shift;
    my $tag         = shift || 'EMPTY';

    return sprintf(
        'Local::%s::%s::%s::%s', __PACKAGE__, 'imported', $module_name,
        $tag
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
