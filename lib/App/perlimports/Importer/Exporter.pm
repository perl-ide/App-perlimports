package App::perlimports::Importer::Exporter;

use strict;
use warnings;

use Try::Tiny ();

sub maybe_require_and_import_module {
    my $module_name    = shift;
    my $attempt_import = shift || 1;

    my $success;
    my $error;

    Try::Tiny::try {
        Module::Runtime::require_module($module_name);
        $success = 1;
    }
    Try::Tiny::catch {
        $error = $_;
    };

    if ($error) {
        return undef, undef, $error;
    }

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
    my @export    = @{ $module_name . '::EXPORT' };
    my @export_ok = @{ $module_name . '::EXPORT_OK' };
    use strict;
## use critic

    return ( \@export, \@export_ok, $error );
}

1;

# ABSTRACT: A sandbox for attempting to import arbitrary modules

=pod

=head1 DESCRIPTION

Importing dozens or hundreds of modules (and their symbols) into a namespace
can lead to methods being redefined etc, so let's really try to sandbox this.

This module tries to detect symbols which are exported via L<Exporter>.

=head2 maybe_require_and_import_module

    use App::perlimports::Importer ();

    my $attempt_import = 1;
    my ( $export, $export_ok, $error )
        = App::perlimports::Importer::maybe_require_and_import_module(
        $module_name, $attempt_import );

=cut
