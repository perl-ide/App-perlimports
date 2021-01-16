package TestHelper;

use strict;
use warnings;

use App::perlimports           ();
use App::perlimports::Document ();
use Path::Tiny qw( path );
use PPI::Document ();
use PPI::Dumper   ();

use Sub::Exporter -setup =>
    { exports => [qw( file2includes ppi_dump source2pi )] };

sub file2includes {
    my $filename = shift;
    my $content  = path($filename)->slurp;
    my $doc      = PPI::Document->new( \$content );

    my $includes = $doc->find(
        sub {
            $_[1]->isa('PPI::Statement::Include');
        }
    );

    my @includes = map { $_->clone } @{$includes};
    return @includes;
}

sub ppi_dump {
    my $doc = shift;
    my $p   = PPI::Dumper->new($doc);
    $p->print;
}

sub source2pi {
    my $filename    = shift;
    my $source_text = shift;
    my $pi_args     = shift;

    my $doc = App::perlimports::Document->new( filename => $filename );
    return App::perlimports->new(
        document => $doc,
        $source_text ? ( source_text => $source_text ) : (),
        %{$pi_args},
    );
}

1;
