package TestHelper;

use strict;
use warnings;

use App::perlimports::Document ();
use App::perlimports::Include  ();
use Log::Dispatch::Array       ();
use Path::Tiny                 qw( path );
use PPI::Document              ();
use PPI::Dumper                ();

use Sub::Exporter -setup => {
    exports => [
        qw(
            doc
            file2includes
            inc
            inspector
            logger
            ppi_dump
            source2pi
        )
    ]
};

sub doc {
    my %args = @_;
    my @log;
    return (
        App::perlimports::Document->new(
            logger => logger( \@log ),
            %args,
        ),
        \@log
    );
}

sub inc {
    my %args = @_;
    my @log;
    return (
        App::perlimports::Include->new(
            logger => logger( \@log ),
            %args,
        ),
        \@log
    );
}

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

sub logger {
    my $target    = shift || die 'log target required';
    my $log_level = shift || 'debug';

    my $log = Log::Dispatch->new;

    $log->add(
        Log::Dispatch::Array->new(
            name      => 'text_table',
            min_level => $log_level,
            array     => $target,
        )
    );

    return $log;
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
    my @logs;
    my $logger = logger( \@logs );

    my $doc = App::perlimports::Document->new(
        filename => $filename,
        logger   => $logger,
        $source_text ? ( selection => $source_text ) : (),
    );

    return App::perlimports::Include->new(
        document => $doc,
        include  => $doc->includes->[0],
        logger   => $logger,
        %{$pi_args},
    );
}

sub inspector {
    my $module = shift;
    my $logs   = [];
    return (
        App::perlimports::ExportInspector->new(
            module_name => $module,
            logger      => logger($logs),
        ),
        $logs
    );
}

1;
