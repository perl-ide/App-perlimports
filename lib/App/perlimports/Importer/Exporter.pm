package App::perlimports::Importer::Exporter;

use strict;
use warnings;

our $VERSION = '0.000001';

use List::Util ();
use Try::Tiny  ();

sub maybe_get_exports {
    my $module_name    = shift;
    my $attempt_import = shift || 1;

    my $error;

    # If this fails, that's ok. No need to return early.
    if ($attempt_import) {

        # This is helpful for (at least) POSIX and Test::Most
        Try::Tiny::try {
            $module_name->import;
        }
        Try::Tiny::catch {
            $error = $_;
        };
    }

## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my @export      = @{ $module_name . '::EXPORT' };
    my @export_ok   = @{ $module_name . '::EXPORT_OK' };
    my @export_fail = @{ $module_name . '::EXPORT_FAIL' };
    my %export_tags = %{ $module_name . '::EXPORT_TAGS' };
    my $isa         = [ @{ $module_name . '::ISA' } ];
    use strict;
## use critic

    return App::perlimports::ExportInspector::Inspection->new(
        {
            all_exports =>
                _list_to_hash( List::Util::uniq( @export, @export_ok ) ),
            @{$isa} ? ( class_isa => $isa ) : (),
            default_exports => _list_to_hash(@export),
            errors          => $error ? [$error] : [],
            export_fail     => \@export_fail,
            export_tags     => \%export_tags,
            is_exporter     => (
                       !!( List::Util::any { $_ eq 'Exporter' } @{$isa} )
                    || !!scalar @export_ok
                    || !!scalar @export
                    || !!scalar @export_fail
                    || !!scalar keys %export_tags
            ),
        }
    );
}

sub _list_to_hash {
    my @list = @_;
    my %hash;
    for my $item (@list) {
        my $value = $item;
        $value =~ s{^&}{};
        $hash{$item} = $value;
    }
    return \%hash;
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
