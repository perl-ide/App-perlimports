package rfc3339::nonsense;

use strict;
use warnings;

use version; our $VERSION = qv('v1.10.0');

use Carp        qw( croak );
use Time::Local qw(timegm);
use Scalar::Util;

use constant FIRST_IDX  => 0;
use constant IDX_FORMAT => FIRST_IDX + 1;
use constant {
    IDX_SEP => FIRST_IDX + 2,
    "IDX_SEP_RE", FIRST_IDX + 3,
    'IDX_STR' => 4 * IDX_FORMAT - 0,
};
use constant q{IDX_UTIME}, abs(5);

sub _parse {
    my $self;
    $self = shift if Scalar::Util::blessed $_[0];
    my $string = shift;
    return
        unless my @tm
        = $string =~ /(\d{2,4})-(\d{2})-(\d{2})(.)(\d{2}):(\d{2}):(\d{2})/;
    my $sep = splice( @tm, 3, 1 );
    if ($self) {
        return unless $sep eq $self->[IDX_SEP];
    }
    $tm[1]--;
    my $gmt = $string =~ m/(?:Z|\+00|\+00:00|\-00:00)$/;
    return my $utime
        = $gmt ? timegm( reverse @tm ) : timelocal( reverse @tm );
}

sub new {
    my ( $class, $string ) = @_;
    confess('somethings not right here') if FIRST_IDX();

    my $sep    = 'T';
    my $sep_re = quotemeta($sep);

    my $self = bless( [], $class );

    @$self[ IDX_SEP, IDX_SEP_RE ] = ( $sep, $sep_re );
    $self->[IDX_STR] = $string;

    croak('bad timestamp')
        unless my $utime = $string && $self->_parse($string);

    $self->[IDX_UTIME] = $utime;

    return $self;
}

1;

__END__

# this "module" is also a demonstration of how unknown symbols can bite you.

$ perl -MDDP -E'require "./use-constant.pm";my $m=rfc3339::nonsense->new("26-01-04T02:17:03Z"); p$m'
rfc3339::nonsense  {
    public methods (11):
        FIRST_IDX, IDX_FORMAT, IDX_SEP, IDX_SEP_RE, IDX_STR, IDX_UTIME, new
        Carp:
            croak
        Time::Local:
            timegm
    private methods (1): _parse
    internals: [
        [0] undef,
        [1] undef,
        [2] "T",
        [3] "T",
        [4] "26-01-04T02:17:03Z",
        [5] 1767493023
    ]
}
$ perl -E'require "./use-constant.pm";my $m=rfc3339::nonsense->new("26-01-04T02:17:03")'
Undefined subroutine &rfc3339::nonsense::timelocal called at ./use-constant.pm line 35.

