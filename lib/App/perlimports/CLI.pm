package App::perlimports::CLI;

use Moo;
use utf8;
use feature qw( say );

our $VERSION = '0.000040';

use App::perlimports           ();
use App::perlimports::Config   ();
use App::perlimports::Document ();
use Capture::Tiny qw( capture_stdout );
use Getopt::Long::Descriptive qw( describe_options );
use Log::Dispatch ();
use Path::Tiny qw( path );
use Try::Tiny qw( catch try );
use Types::Standard qw( ArrayRef Bool HashRef InstanceOf Object Str );

has _args => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_args',
);

has _config => (
    is      => 'ro',
    isa     => InstanceOf [App::perlimports::Config::],
    lazy    => 1,
    builder => '_build_config',
);

has _config_file => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'config',
    builder  => '_build_config_file',
);

# off by default
has _inplace_edit => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return
            defined $self->_opts->inplace_edit
            ? $self->_opts->inplace_edit
            : 0;
    },
);

has _opts => (
    is      => 'ro',
    isa     => InstanceOf ['Getopt::Long::Descriptive::Opts'],
    lazy    => 1,
    default => sub { $_[0]->_args->{opts} },
);

# off by default
has _read_stdin => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return
              defined $self->_opts->read_stdin ? $self->_opts->read_stdin
            : defined $self->_config->{read_stdin}
            ? $self->_config->{read_stdin}
            : 0;
    },
);

has _usage => (
    is      => 'ro',
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
            'filename|f=s',
            'A file you would like to run perlimports on. Alternatively, just provide a list of one or more file names without a named parameter as the last arguments to this script: perlimports file1 file2 file3'
        ],
        [],
        [
            'config-file=s',
            'Path to a perlimports config file. If this parameter is not supplied, we will look for a file called perlimports.toml or .perlimports.toml in the current directory and then look for a perlimports.toml in XDG_CONFIG_HOME (usually something like $HOME/perlimports/perlimports.toml). This behaviour can be disabled via --no-config-file as described below.'
        ],
        [],
        [
            'create-config-file=s',
            'Create a sample config file using the supplied name and then exit.',
            { shortcircuit => 1 }
        ],
        [],
        [
            'ignore-modules=s',
            'Comma-separated list of modules to ignore.'
        ],
        [],
        [
            'ignore-modules-pattern=s',
            'Regular expression that matches modules to ignore.'
        ],
        [],
        [
            'cache!',
            '(Experimental and currently discouraged.) Cache some objects in order to speed up subsequent runs. Defaults to no cache.',
        ],
        [],
        [
            'ignore-modules-filename=s',
            'Path to file listing modules to ignore. One per line.'
        ],
        [],
        [
            'ignore-modules-pattern-filename=s',
            'Path to file listing regular expressions that matches modules to ignore. One per line.'
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
        [ 'inplace-edit|i', 'Edit the file in place.' ],
        [],
        [
            'libs=s',
            'Comma-separated list of library paths to include (eg --libs lib,t/lib,dev/lib)',

        ],
        [],
        [
            'no-config-file',
            'Do not look for a perlimports config file.'
        ],
        [],
        [
            'padding!',
            'Pad imports: qw( foo bar ) vs qw(foo bar). Defaults to true',
        ],
        [],
        [
            'read-stdin',
            'Read statements to process from STDIN rather than the supplied file.',
        ],
        [],
        [
            'preserve-duplicates!',
            'Preserve duplicate use statements for the same module. This is the default behaviour. You are encouraged to disable it.',
        ],
        [],
        [
            'preserve-unused!',
            'Preserve use statements for modules which appear to be unused. This is the default behaviour. You are encouraged to disable it.',
        ],
        [],
        [
            'tidy-whitespace!',
            'Reformat use statements even when changes are only whitespace. This is the default behaviour.',
        ],
        [],
        [],
        [ 'version', 'Print installed version', { shortcircuit => 1 } ],
        [
            'log-level|l=s', 'Print messages to STDERR',
        ],
        [
            'log-filename=s', 'Log messages to file rather than STDERR',
        ],
        [ 'help', 'Print usage message and exit', { shortcircuit => 1 } ],
        [
            'verbose-help', 'Print usage message and documentation ',
            { shortcircuit => 1 }
        ],
    );

    return { opts => $opt, usage => $usage, };
}

sub _build_config {
    my $self = shift;
    my %config;
    if ( !$self->_opts->no_config_file && $self->_config_file ) {
        %config = %{ $self->_read_config_file };

        # The Bool type provided by Types::Standard doesn't seem to like
        # JSON::PP::Boolean
        for my $key ( keys %config ) {
            my $maybe_bool = $config{$key};
            my $ref        = ref $maybe_bool;
            next unless $ref;

            if (   $ref eq 'JSON::PP::Boolean'
                || $ref eq 'Types::Serializer::Boolean' ) {
                $config{$key} = $$maybe_bool ? 1 : 0;
            }
        }
    }

    my @config_options = qw(
        cache
        ignore_modules_filename
        ignore_modules_pattern
        log_filename
        log_level
        never_export_modules_filename
        padding
        preserve_duplicates
        preserve_unused
        tidy_whitespace
    );
    my @config_option_lists
        = ( 'ignore_modules', 'libs', 'never_export_modules' );

    my %args = map { $_ => $self->_opts->$_ }
        grep { defined $self->_opts->$_ } @config_options;

    for my $list (@config_option_lists) {
        my $val = $self->_opts->$list;
        if ( defined $val ) {
            $args{$list} = [ split m{,}, $val ];
        }
    }
    return App::perlimports::Config->new( %config, %args );
}

sub _build_config_file {
    my $self = shift;

    if ( $self->_opts->config_file ) {
        if ( !-e $self->_opts->config_file ) {
            warn $self->_opts->config_file . ' not found';
            exit(1);
        }
        return $self->_opts->config_file;
    }

    my @filenames = ( 'perlimports.toml', '.perlimports.toml', );

    for my $name (@filenames) {
        return $name if -e $name;
    }

    require File::XDG;

    my $xdg_config = File::XDG->new( name => 'perlimports', api => 1 );
    my $file       = $xdg_config->config_home->child( $filenames[0] );
    return -e $file ? $file : q{};
}

sub _read_config_file {
    my $self = shift;

    require TOML::Tiny;
    my $config = TOML::Tiny::from_toml( path( $self->_config_file )->slurp );
    return $config || {};
}

sub run {
    my $self = shift;
    my $opts = $self->_opts;

    ( print $VERSION, "\n" )      && return if $opts->version;
    ( print $self->_usage->text ) && return if $opts->help;

    if ( $opts->verbose_help ) {
        print $self->_usage->text;
        require Pod::Usage;    ## no perlimports
        Pod::Usage::pod2usage( ( { -exitval => 0 } ) );
        return;
    }

    if ( $opts->create_config_file ) {
        try {
            my $file
                = App::perlimports::Config->create_config(
                $opts->create_config_file );
        }
        catch {
            print STDERR $_, "\n";
            exit(1);
        };
        exit(0);
    }

    my $input;

    if ( $self->_read_stdin ) {
        local $/;
        $input = <STDIN>;
    }

    unshift @INC, @{ $self->_config->libs };

    my $logger
        = $self->_has_logger
        ? $self->logger
        : Log::Dispatch->new(
        outputs => [
            $self->_config->log_filename
            ? [
                'File',
                binmode   => ':encoding(UTF-8)',
                filename  => $self->_config->log_filename,
                min_level => $self->_config->log_level,
                mode      => '>>',
                newline   => 1,
                ]
            : [
                'Screen',
                min_level => $self->_config->log_level,
                newline   => 1,
                stderr    => 1,
                utf8      => 1,
            ]
        ]
        );

    my @files = ( $opts->filename || @ARGV );
    unless (@files) {
        say STDERR q{Mandatory parameter 'filename' missing};
        print STDERR $self->_usage->text;
        exit(1);
    }

    foreach my $filename (@files) {
        if ( !path($filename)->is_file ) {
            say STDERR "$filename does not appear to be a file";
            print STDERR $self->_usage->text;
            exit(1);
        }

        $logger->notice( '🚀 Starting file: ' . $filename );

        # Capture STDOUT here so that 3rd party code printing to STDOUT doesn't get
        # piped back into vim.
        my ( $stdout, $tidied ) = capture_stdout(
            sub {
                my $pi_doc = App::perlimports::Document->new(
                    cache    => $self->_config->cache,
                    filename => $filename,
                    @{ $self->_config->ignore }
                    ? ( ignore_modules => $self->_config->ignore )
                    : (),
                    @{ $self->_config->ignore_pattern }
                    ? ( ignore_modules_pattern =>
                            $self->_config->ignore_pattern )
                    : (),
                    @{ $self->_config->never_export }
                    ? ( never_export_modules => $self->_config->never_export )
                    : (),
                    logger              => $logger,
                    padding             => $self->_config->padding,
                    preserve_duplicates =>
                        $self->_config->preserve_duplicates,
                    preserve_unused => $self->_config->preserve_unused,
                    tidy_whitespace => $self->_config->tidy_whitespace,
                    $input ? ( selection => $input ) : (),
                );

                return $pi_doc->tidied_document;
            }
        );

        if ( $self->_read_stdin ) {
            print STDOUT $tidied;
        }
        elsif ( $self->_inplace_edit ) {

            # append() with truncate, because spew() can change file permissions
            path($filename)->append( { truncate => 1 }, $tidied );
        }
        else {
            print STDOUT $tidied;
        }
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
