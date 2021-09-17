package App::perlimports::Annotations;

# Some of this logic was lifted directly from Perl::Critic::Annotation

use Moo;

our $VERSION = '0.000020';

use Types::Standard qw( ArrayRef Object );

has _annotations => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_annotations',
);

has _ppi_document => (
    is       => 'ro',
    isa      => Object,
    init_arg => 'ppi_document',
    required => 1,
);

sub _build_annotations {
    my $self = shift;

    my @found = ();
    my $comments
        = $self->_ppi_document->find('PPI::Token::Comment') || return [];
    my $disable_rx = qr{[#][#] \s* no  \s+ perlimports}xms;
    my $enable_rx  = qr{[#][#] \s* use \s+ perlimports}xms;

    my @enabled = ( grep { $_ =~ $enable_rx } @{$comments} );

    for my $element ( grep { $_ =~ $disable_rx } @{$comments} ) {

        my %found = (
            column_number => $element->column_number,
            line_number   => $element->logical_line_number,
            range         => [
                $element->logical_line_number,
                $element->column_number > 1
                ? ( $element->logical_line_number )
                : ()
            ],
        );

        # Seek ahead to see if/when perlimpts is re-enabled
        if ( $element->column_number == 1 ) {
            for my $on (@enabled) {
                if (   $on->column_number == 1
                    && $on->logical_line_number
                    > $element->logical_line_number ) {
                    $found{range}->[1] = $on->logical_line_number;
                }
            }
        }
        push @found, \%found;
    }

    return \@found;
}

sub is_ignored {
    my $self    = shift;
    my $element = shift;
    unless ( $element && ref($element) && $element->isa('PPI::Element') ) {
        die 'PPI::Element required';
    }

    my $line = $element->logical_line_number;
    for my $a ( @{ $self->_annotations } ) {
        my ( $min, $max ) = @{ $a->{range} };
        if ( $line >= $min && ( !$max || $line <= $max ) ) {
            return 1;
        }

        # Any further annotations do not apply to this element
        last if $line < $max;
    }

    return 0;
}

1;

# ABSTRACT: Find line ranges where perlimports has been disabled

=head1 SYNOPSIS

    my $anno = App::perlimports::Annotations->new(
        ppi_document => $ppi_doc
    );

    print 'skip include' if $anno->is_ignored( $ppi_element );

=head2 is_ignored( $ppi_element )

Returns true if the provided L<PPI::Element> is in an ignored line range.
