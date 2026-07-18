package App::perlimports::Sorter;

use Moo;
use utf8;

use App::perlimports::Annotations ();
use PPI::Document                 ();
use Types::Standard               qw( Str );

our $VERSION = '0.000001';

has logger => (
    is       => 'ro',
    required => 1,
);

has source => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub sorted_document {
    my $self = shift;

    my $source = $self->source;
    my $doc    = PPI::Document->new( \$source );
    return $source unless $doc;
    $doc->index_locations;

    my $found
        = $doc->find( sub { $_[1]->isa('PPI::Statement::Include') } );
    return $source unless $found && @{$found};

    my $annotations = App::perlimports::Annotations->new(
        ppi_document => $doc,
        logger       => $self->logger,
    );

    # Each element retains its trailing "\n"; line N is $lines[N - 1].
    my @lines = split /(?<=\n)/, $source;

    my @units = map { $self->_unit( $_, $annotations, \@lines ) } @{$found};

    my @sections = $self->_sections( \@units, \@lines );

    # Rewrite bottom-up so earlier line numbers stay valid across splices.
    my $changed = 0;
    for my $section ( reverse @sections ) {
        my ( $new_text, $section_changed )
            = $self->_reorder_section( $section, \@lines );
        next unless $section_changed;

        $changed = 1;
        my $first = $section->[0]{lead};
        my $end   = $section->[-1]{end};
        splice @lines, $first - 1, $end - $first + 1, $new_text;
    }

    return $changed ? join( q{}, @lines ) : $source;
}

# Build a unit hashref describing one include and the source lines it owns.
sub _unit {
    my ( $self, $node, $annotations, $lines ) = @_;

    my $start    = $node->line_number;
    my $newlines = () = $node->content =~ /\n/g;
    my $end      = $start + $newlines;

    # Absorb full-line comments directly above the statement (no blank line
    # can appear here: a blank line would have ended the section).
    my $lead = $start;
    while ( $lead - 1 >= 1 && $lines->[ $lead - 2 ] =~ /\A\s*#/ ) {
        $lead--;
    }

    return {
        lead  => $lead,
        start => $start,
        end   => $end,
        class => $self->_classify( $node, $annotations ),
        key   => lc( $node->module // q{} ),
    };
}

sub _classify {
    my ( $self, $node, $annotations ) = @_;

    return 'hoist'  if $node->pragma;
    return 'hoist'  if $node->version;
    return 'anchor' if $annotations->is_ignored($node);
    return 'anchor' if ( $node->type // q{} ) eq 'no';
    return 'anchor' unless defined $node->module && length $node->module;
    return 'sortable';
}

# Group units into contiguous sections.
sub _sections {
    my ( $self, $units, $lines ) = @_;

    my @sections;
    my @current;
    for my $u ( @{$units} ) {
        if (@current) {
            my $prev = $current[-1];
            my $same = 1;
            for my $ln ( $prev->{end} + 1 .. $u->{start} - 1 ) {
                unless ( $lines->[ $ln - 1 ] =~ /\A\s*#/ ) {
                    $same = 0;
                    last;
                }
            }
            if ( !$same ) {
                push @sections, [@current];
                @current = ();
            }
        }
        push @current, $u;
    }
    push @sections, [@current] if @current;

    return @sections;
}

# Return ( $new_section_text, $changed_bool ) for one section.
sub _reorder_section {
    my ( $self, $section, $lines ) = @_;

    # If any two units share or overlap a physical line, reordering would
    # duplicate or merge the user's source. We cannot safely sort statements
    # that share a line, so leave the whole section byte-identical.
    for my $i ( 0 .. $#{$section} - 1 ) {
        return ( q{}, 0 )
            if $section->[$i]{end} >= $section->[ $i + 1 ]{lead};
    }

    my @hoist   = grep { $_->{class} eq 'hoist' } @{$section};
    my @modules = grep { $_->{class} ne 'hoist' } @{$section};

    my @sortable = sort { $a->{key} cmp $b->{key} }
        grep { $_->{class} eq 'sortable' } @modules;

    my @ordered_modules;
    my $si = 0;
    for my $u (@modules) {
        push @ordered_modules,
            $u->{class} eq 'anchor' ? $u : $sortable[ $si++ ];
    }

    my $text_of = sub {
        my $u = shift;
        return join q{}, @{$lines}[ $u->{lead} - 1 .. $u->{end} - 1 ];
    };

    # Normalize each unit's text to end in exactly one newline so reordered
    # units never jam onto one line when the final unit lacked a trailing "\n".
    my $rendered = sub {
        my $text = $text_of->(shift);
        $text =~ s/\n?\z/\n/;
        return $text;
    };

    my $new_text = q{};
    $new_text .= $rendered->($_) for @hoist;
    $new_text .= "\n" if @hoist && @ordered_modules;     # set pragmas off
    $new_text .= $rendered->($_) for @ordered_modules;

    my $old_text = join q{}, map { $text_of->($_) } @{$section};

    # Preserve the section's original trailing-newline state: if the source
    # had no final "\n", do not add bytes the user did not have.
    $new_text =~ s/\n\z// unless $old_text =~ /\n\z/;

    return ( $new_text, $new_text ne $old_text );
}

1;

# ABSTRACT: Sort a document's include statements
