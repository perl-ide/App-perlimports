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

