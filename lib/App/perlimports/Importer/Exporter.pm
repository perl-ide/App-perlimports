package App::perlimports::Importer::Exporter;

use strict;
use warnings;

our $VERSION = '0.000001';

use List::Util  ();
use Symbol::Get ();
use Try::Tiny   ();

sub maybe_get_exports {
    my $module_name = shift;
    my $logger      = shift;

    my $error;

    my $log_sub = sub {
        $logger->info(
            sprintf(
                'Trying to import %s in %s: %s',
                $module_name,
                __PACKAGE__,
                $_[0]
            )
        );
    };

    local $SIG{__WARN__} = $log_sub;

    my $pkg_to_eval = _pkg_for_eval($module_name);
    my $to_eval     = <<"EOF";
package $pkg_to_eval;
use $module_name;
EOF

    local $@;
    eval $to_eval;

    if ($@) {
        $log_sub->($@);
    }

    print $to_eval;
## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my @export      = @{ $module_name . '::EXPORT' };
    my @export_ok   = @{ $module_name . '::EXPORT_OK' };
    my @export_fail = @{ $module_name . '::EXPORT_FAIL' };
    my %export_tags = %{ $module_name . '::EXPORT_TAGS' };
    my @isa         = @{ $module_name . '::ISA' };
    use strict;
## use critic

    my $implicit_exports = _list_to_hash( $module_name, \@export );
    my $explicit_exports
        = _list_to_hash( $module_name, [ @export, @export_ok ] );

    # Exporter combines @EXPORT and @EXPORT_OK when checking valid explicit
    # import names.
    return App::perlimports::ExportInspector::Inspection->new(
        {
            scalar @isa ? ( class_isa => \@isa ) : (),
            explicit_exports => $explicit_exports,
            export_fail      => \@export_fail,
            export_tags      => \%export_tags,
            implicit_exports => $implicit_exports,
            inspected_by     => __PACKAGE__,
            is_exporter      => (
                       !!( List::Util::any { $_ eq 'Exporter' } @isa )
                    || !!scalar @export_ok
                    || !!scalar @export
                    || !!scalar @export_fail
                    || !!scalar keys %export_tags
            ),
            logger => $logger,
        }
    );
}

sub _list_to_hash {
    my $module_name = shift;
    my $list        = shift;

    my %hash;
    for my $item ( @{$list} ) {
        my $value = $item;
        $value =~ s{^&}{};
        $hash{$item} = $value;
    }
    for my $key ( keys %hash ) {
        if ( substr( $key, 0, 1 ) eq '*' ) {
            my $thing = substr( $key, 1 );
            for my $sigil ( '&', '$', '@', '%' ) {
                my $symbol_name = $sigil . $module_name . '::' . $thing;
                if ( Symbol::Get::get($symbol_name) ) {
                    $hash{ $sigil . $thing } = $key;
                }
            }
        }
    }

    return \%hash;
}

sub _pkg_for_eval {
    my $module_name = shift;

    return sprintf(
        'Local::%s::%s::%s', __PACKAGE__, 'imported', $module_name,
    );
}
1;

# ABSTRACT: A sandbox for attempting to import arbitrary modules

=pod

=head1 DESCRIPTION

Importing dozens or hundreds of modules (and their symbols) into a namespace
can lead to methods being redefined etc, so let's really try to sandbox this.

This module tries to detect symbols which are exported via L<Exporter>.

=head2 maybe_get_exports

    use App::perlimports::Importer ();

    my $attempt_import = 1;
    my $export_data
        = App::perlimports::Importer::maybe_get_exports(
        $module_name, $attempt_import );

=cut
