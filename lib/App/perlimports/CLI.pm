package App::perlimports::CLI;

use Moo;

our $VERSION = '0.000001';

use App::perlimports           ();
use App::perlimports::Document ();
use Data::Printer;
use Getopt::Long::Descriptive qw( describe_options );
use List::Util qw( uniq );
use Path::Tiny qw( path );
use Pod::Usage qw( pod2usage );
use Try::Tiny qw( catch try );
use Types::Standard qw( ArrayRef HashRef InstanceOf Str );

has _args => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_args',
);

has _ignore_modules => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_ignore_modules',
);

has _never_exports => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_never_exports',
);

has _opts => (
    is      => 'rw',
    isa     => InstanceOf ['Getopt::Long::Descriptive::Opts'],
    lazy    => 1,
    default => sub { $_[0]->_args->{opts} },
);

has _usage => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub { $_[0]->_args->{usage} },
);

sub _build_args {
    my $self = shift;
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
    return { opts => $opt, usage => $usage, };
}

sub _build_ignore_modules {
    my $self = shift;
    my @ignore_modules
        = $self->_opts->ignore_modules
        ? split m{,}, $self->_opts->ignore_modules
        : ();

    if ( $self->_opts->ignore_modules_filename ) {
        my @from_file
            = path( $self->_opts->ignore_modules_filename )
            ->lines( { chomp => 1 } );
        @ignore_modules = uniq( @ignore_modules, @from_file );
    }
    return \@ignore_modules;
}

sub _build_never_exports {
    my $self = shift;

    my @never_exports
        = $self->_opts->never_export_modules
        ? split m{,}, $self->_opts->never_export_modules
        : ();

    if ( $self->_opts->never_export_modules_filename ) {
        my @from_file
            = path( $self->_opts->never_export_modules_filename )
            ->lines( { chomp => 1 } );
        @never_exports = uniq( @never_exports, @from_file );
    }
    return \@never_exports;
}

sub run {
    my $self = shift;

    my $opts = $self->_opts;

    if ( $opts->help ) {
        print $self->_usage->text;
        return;
    }

    if ( $opts->verbose_help ) {
        print $self->_usage->text;
        print pod2usage();
        return;
    }

    if ( $opts->version ) {
        print $App::perlimports::VERSION;
        return;
    }

    my $input;

    if ( $opts->read_stdin ) {
        local $/;
        $input = <STDIN>;
    }
    else {
        $input = path( $opts->filename )->slurp;
    }

    my $doc = PPI::Document->new( \$input );

    my $includes = $doc->find(
        sub {
            $_[1]->isa('PPI::Statement::Include');
        }
    ) || [];

    if ( $opts->libs ) {
        unshift @INC, ( split m{,}, $opts->libs );
    }

    my $pi_doc = App::perlimports::Document->new(
        filename => $opts->filename,
        @{ $self->_never_exports }
        ? ( never_export_modules => $self->_never_exports )
        : (),
    );

    foreach my $include ( @{$includes} ) {
        my $e = App::perlimports->new(
            document => $pi_doc,
            @{ $self->_ignore_modules }
            ? ( ignored_modules => $self->_ignore_modules )
            : (),

            include     => $include,
            pad_imports => $opts->padding,
        );

        my $elem;
        try {
            $elem = $e->formatted_ppi_statement;
        }
        catch {
            print STDERR 'Error: ' . $opts->filename . "\n";
            print STDERR $include;
            print STDERR $_;
        };

        next unless $elem;

        # https://github.com/adamkennedy/PPI/issues/189
        $include->insert_before( $elem->clone );
        $include->remove;

        if ( $opts->verbose && $e->has_errors ) {
            print STDERR 'Error: ' . $opts->filename . "\n";
            print STDERR $e->_module_name . ' ' . np( $e->errors ) . "\n";
        }
    }

    # We need to do this in order to preserve HEREDOCs.
    # See https://metacpan.org/pod/PPI::Document#serialize
    my $serialized = $doc->serialize;

    if ( $opts->read_stdin ) {
        print $serialized;
    }
    elsif ( $opts->inplace_edit ) {
        path( $opts->filename )->spew($serialized);
    }
    else {
        print $serialized;
    }
}

1;

__END__

# ABSTRACT: CLI arg parsing for C<perlimports>

=pod

=head1 DESCRIPTION

This module isn't really meant to provide a public interface.

=head2 run()

The method which will do the argument parsing and print out the results.

=cut
