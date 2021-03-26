package App::perlimports::CLI;

use Moo;
use utf8;

our $VERSION = '0.000001';

use App::perlimports           ();
use App::perlimports::Document ();
use Capture::Tiny qw( capture_stdout );
use Getopt::Long::Descriptive qw( describe_options );
use List::Util qw( uniq );
use Log::Dispatch ();
use Path::Tiny qw( path );
use Pod::Usage qw( pod2usage );
use Types::Standard qw( ArrayRef HashRef InstanceOf Object Str );

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
    isa     => Object,
    lazy    => 1,
    default => sub { $_[0]->_args->{usage} },
);

with 'App::perlimports::Role::Logger';

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
        [ 'version', 'Print installed version', { shortcircuit => 1 } ],
        [
            'log-level|l=s', 'Print messages to STDERR',
            { default => 'error' }
        ],
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

    ( print $VERSION )            && return if $opts->version;
    ( print $self->_usage->text ) && return if $opts->help;

    if ( $opts->verbose_help ) {
        print $self->_usage->text;
        print pod2usage();
        return;
    }

    my $input;

    if ( $opts->read_stdin ) {
        local $/;
        $input = <STDIN>;
    }

    if ( $opts->libs ) {
        unshift @INC, ( split m{,}, $opts->libs );
    }

    my $logger
        = $self->_has_logger
        ? $self->logger
        : Log::Dispatch->new(
        outputs => [
            [
                'Screen',
                min_level => $opts->log_level,
                newline   => 1,
                utf8      => 1,
            ]
        ]
        );

    $logger->info( '🚀 Starting file: ' . $opts->filename );

    # Capture STDOUT here so that 3rd party code printing to STDOUT doesn't get
    # piped back into vim.
    my ( $stdout, $tidied ) = capture_stdout(
        sub {
            my $pi_doc = App::perlimports::Document->new(
                filename => $opts->filename,
                @{ $self->_ignore_modules }
                ? ( ignore_modules => $self->_ignore_modules )
                : (),
                @{ $self->_never_exports }
                ? ( never_export_modules => $self->_never_exports )
                : (),
                logger  => $logger,
                padding => $opts->padding,
                $input ? ( selection => $input ) : (),
            );

            return $pi_doc->tidied_document;
        }
    );

    if ( $opts->read_stdin ) {
        print $tidied;
    }
    elsif ( $opts->inplace_edit ) {
        path( $opts->filename )->spew($tidied);
    }
    else {
        print $tidied;
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
