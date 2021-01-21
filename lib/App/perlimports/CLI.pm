package App::perlimports::CLI;

use strict;
use warnings;

use Moo;

use App::perlimports           ();
use App::perlimports::Document ();
use Data::Printer;
use Getopt::Long::Descriptive qw( describe_options );
use List::Util qw( uniq );
use Path::Tiny qw( path );
use Pod::Usage qw( pod2usage );
use Try::Tiny qw( catch try );

sub run {
    my ( $opt, $usage ) = describe_options(
        'perlimports %o',
        [
            'filename|f=s', 'The file containing the imports',
            { required => 1 }
        ],
        [],
        [
            'ignore-modules=s',
            'Comma-separated list of modules to ignore.'
        ],
        [],
        [
            'ignore-modules-filename=s',
            'Path to file listing modules to ignore. One per line.'
        ],
        [],
        [
            'never-export-modules=s',
            'Comma-separated list of modules which do not export symbols.'
        ],
        [],
        [
            'never-export-modules-filename=s',
            q{Path to file listing modules which don't export symbols. One per line.}
        ],
        [],
        [ 'inplace-edit|i', 'edit the file in place' ],
        [],
        [
            'libs=s',
            'Comma-separated list of library paths to include (eg --libs lib,t/lib,dev/lib)',

        ],
        [],
        [
            'padding!',
            'pad imports: qw( foo bar ) vs qw(foo bar). Defaults to true',
            { default => 1 },

        ],
        [],
        [
            'read-stdin',
            'Read statements to process from STDIN rather than the supplied file',
        ],
        [],
        [],
        [ 'version',   'Print installed version', { shortcircuit => 1 } ],
        [ 'verbose|v', 'Print errors to STDERR' ],
        [ 'help', "Print usage message and exit", { shortcircuit => 1 } ],
        [
            'verbose-help', "Print usage message and documentation ",
            { shortcircuit => 1 }
        ],
    );

    if ( $opt->help ) {
        print $usage->text;
        exit;
    }

    if ( $opt->verbose_help ) {
        print $usage->text;
        print pod2usage();
        exit;
    }

    if ( $opt->version ) {
        print $App::perlimports::VERSION;
        exit;
    }

    my $input;

    if ( $opt->read_stdin ) {
        local $/;
        $input = <STDIN>;
    }
    else {
        $input = path( $opt->filename )->slurp;
    }

    my $doc = PPI::Document->new( \$input );

    my $includes = $doc->find(
        sub {
            $_[1]->isa('PPI::Statement::Include');
        }
    ) || [];

    if ( $opt->libs ) {
        unshift @INC, ( split m{,}, $opt->libs );
    }

    my @ignore_modules
        = $opt->ignore_modules
        ? split m{,}, $opt->ignore_modules
        : ();

    if ( $opt->ignore_modules_filename ) {
        my @from_file
            = path( $opt->ignore_modules_filename )->lines( { chomp => 1 } );
        @ignore_modules = uniq( @ignore_modules, @from_file );
    }

    my @never_exports
        = $opt->never_export_modules
        ? split m{,}, $opt->never_export_modules
        : ();

    if ( $opt->never_export_modules_filename ) {
        my @from_file
            = path( $opt->never_export_modules_filename )
            ->lines( { chomp => 1 } );
        @never_exports = uniq( @never_exports, @from_file );
    }

    my $pi_doc = App::perlimports::Document->new(
        filename => $opt->filename,
        @never_exports
        ? ( never_export_modules => \@never_exports )
        : (),
    );

    foreach my $include ( @{$includes} ) {
        my $e = App::perlimports->new(
            document => $pi_doc,
            @ignore_modules
            ? ( ignored_modules => \@ignore_modules )
            : (),
            include     => $include,
            pad_imports => $opt->padding,
        );

        my $elem;
        try {
            $elem = $e->formatted_ppi_statement;
        }
        catch {
            print STDERR 'Error: ' . $opt->filename . "\n";
            print STDERR $include;
            print STDERR $_;
        };

        next unless $elem;

        # https://github.com/adamkennedy/PPI/issues/189
        $include->insert_before( $elem->clone );
        $include->remove;

        if ( $opt->verbose && $e->has_errors ) {
            print STDERR 'Error: ' . $opt->filename . "\n";
            print STDERR $e->_module_name . ' ' . np( $e->errors ) . "\n";
        }
    }

    # We need to do this in order to preserve HEREDOCs.
    # See https://metacpan.org/pod/PPI::Document#serialize
    my $serialized = $doc->serialize;

    if ( $opt->read_stdin ) {
        print $serialized;
    }
    elsif ( $opt->inplace_edit ) {
        path( $opt->filename )->spew($serialized);
    }
    else {
        print $serialized;
    }
}

1;

__END__

# ABSTRACT: CLI arg parsing for C<perlimports>

=pod

=head1 SYNOPSIS

=cut
