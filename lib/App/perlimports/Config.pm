package App::perlimports::Config;

use Moo;
use MooX::StrictConstructor;

our $VERSION = '0.000059';

use List::Util      qw( uniq );
use Path::Tiny      qw( path );
use Types::Standard qw( ArrayRef Bool InstanceOf Str );

has cache => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 0,
);

has _ignore_modules => (
    is       => 'ro',
    isa      => ArrayRef,
    init_arg => 'ignore_modules',
    lazy     => 1,
    default  => sub { [] },
);

has _ignore_modules_filename => (
    is        => 'ro',
    isa       => Str,
    init_arg  => 'ignore_modules_filename',
    predicate => '_has_ignore_modules_filename',
);

has _ignore_modules_pattern => (
    is        => 'ro',
    isa       => ArrayRef [Str],
    init_arg  => 'ignore_modules_pattern',
    lazy      => 1,
    predicate => '_has_ignore_modules_pattern',
    coerce    => sub { return ref $_[0] ? $_[0] : [ $_[0] ] },
);

has _ignore_modules_pattern_filename => (
    is        => 'ro',
    isa       => Str,
    init_arg  => 'ignore_modules_pattern_filename',
    predicate => '_has_ignore_modules_pattern_filename',
);

has ignore => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_ignore',
);

has ignore_pattern => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_ignore_pattern',
);

has libs => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub { [] },
);

has log_filename => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { q{} },
);

has log_level => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { 'error' },
);

has _never_export_modules => (
    is       => 'ro',
    isa      => ArrayRef,
    init_arg => 'never_export_modules',
    lazy     => 1,
    default  => sub { [] },
);

has _never_export_modules_filename => (
    is        => 'ro',
    isa       => Str,
    init_arg  => 'never_export_modules_filename',
    predicate => '_has_never_export_modules_filename',
);

has never_export => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_never_export',
);

has padding => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 1,
);

has skip_empty_imports => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 0,
);

has preserve_duplicates => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 1,
);

has preserve_unused => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 1,
);

has tidy_whitespace => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => 1,
);

with 'App::perlimports::Role::Logger';

sub _build_ignore {
    my $self = shift;
    return $self->_aggregate(
        $self->_ignore_modules,
        '_ignore_modules_filename'
    );
}

sub _build_ignore_pattern {
    my $self = shift;
    return $self->_aggregate(
        $self->_ignore_modules_pattern,
        '_ignore_modules_pattern_filename'
    );
}

sub _build_never_export {
    my $self = shift;
    return $self->_aggregate(
        $self->_never_export_modules,
        '_never_export_modules_filename'
    );
}

sub _aggregate {
    my $self     = shift;
    my $list     = shift || [];
    my $accessor = shift;

    my $predicate = '_has' . $accessor;

    return $list if !$self->$predicate;

    my $filename = $self->$accessor;
    return $list if !$filename;    # could be an empty string

    die "File $filename not found" unless -e $filename;

    return [ uniq( @{$list}, path($filename)->lines( { chomp => 1 } ) ) ];
}

sub create_config {
    shift;                         # $class
    my $filename = shift;

    if ( -e $filename ) {
        die "$filename already exists";
    }

    my @toml = <DATA>;
    path($filename)->spew(@toml);
}

1;

# ABSTRACT: Generic configuration options for C<perlimports>

=pod

=head1 DESCRIPTION

This module isn't really meant to provide a public interface.

=head2 create_config( $filename )

This class method creates a L<perlimports> config file at the provided
filename. Dies if the file already exists.

=cut

__DATA__
# Valid log levels are:
# debug, info, notice, warning, error, critical, alert, emergency
# critical, alert and emergency are not currently used.
#
# Please use boolean values in this config file. Negated options (--no-*) are
# not permitted here. Explicitly set options to true or false.
#
# Some of these values deviate from the regular perlimports defaults. In
# particular, you're encouraged to leave preserve_duplicates and
# preserve_unused disabled.

cache                           = false # setting this to true is currently discouraged
ignore_modules                  = []
ignore_modules_filename         = ""
ignore_modules_pattern          = "" # regex like "^(Foo|Foo::Bar)"
ignore_modules_pattern_filename = ""
libs                            = ["lib", "t/lib"]
log_filename                    = ""
log_level                       = "warn"
never_export_modules            = []
never_export_modules_filename   = ""
padding                         = true
preserve_duplicates             = false
preserve_unused                 = false
tidy_whitespace                 = true
skip_empty_imports              = false
