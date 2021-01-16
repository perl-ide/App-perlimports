package TestHelper;

use strict;
use warnings;

use Path::Tiny qw( path );
use PPI::Document ();
use PPI::Dumper   ();

use Sub::Exporter -setup => { exports => [qw( file2includes ppi_dump )] };

sub file2includes {
    my $filename = shift;
    my $content  = path('test-data')->child($filename)->slurp;
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

1;
