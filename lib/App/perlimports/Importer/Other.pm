package App::perlimports::Importer::Other;

use strict;
use warnings;

our $VERSION = '0.000001';

use App::perlimports::ExportInspector::Inspection ();
use List::Util qw( any );
use Symbol::Get ();

sub maybe_get_exports {
    my $module_name = shift;
    my $logger      = shift;

    die 'logger required' unless $logger;

    my @error;
    my @warning;

    my $implicit_exports = _exports_for( $module_name, $logger );

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my @isa = @{ $module_name . '::ISA' };
    use strict;
    ## use critic

    # We don't have a good way of finding explicit exports in this case, so
    # we'll use a copy of the implicit exports because it's better than nothing
    # and may occasionally be correct.
    return App::perlimports::ExportInspector::Inspection->new(
        {
            @isa ? ( class_isa => \@isa ) : (),
            explicit_exports => $implicit_exports,
            implicit_exports => $implicit_exports,
            inspected_by     => __PACKAGE__,
            logger           => $logger,
        }
    );
}

sub _exports_for {
    my $module_name = shift;
    my $logger      = shift;

    my $pkg = _pkg_for($module_name);

    my $use_statement = "use $module_name;";

    # If you're importing Moose into a namespace and following that with an
    # import of namespace::autoclean, you may find that symbols like "after"
    # and "around" are no longer found.
    #
    # We log available symbols inside the BEGIN block in order to defeat
    # namespace::autoclean, which removes symbols from the stash after
    # compilation but before runtime. Thanks to Florian Ragwizt for the tip and
    # the preceding explanation.

    my $to_eval = <<"EOF";
package $pkg;

use Symbol::Get;
$use_statement;
our \@__EXPORTABLES;

BEGIN {
    \@__EXPORTABLES = Symbol::Get::get_names();
}
1;
EOF

    my $logger_cb = sub {
        my $msg = shift;
        $logger->info(
            sprintf(
                'eval %s in %s: %s',
                $pkg,
                __PACKAGE__,
                $msg,
            )
        );
    };

    local $SIG{__WARN__} = $logger_cb;

    local $@;
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval $to_eval;

    if ($@) {
        $logger_cb->($@);
    }

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my %export = map { $_ => $_ }
        grep { $_ !~ m{(?:BEGIN|ISA|__EXPORTABLES)} && $_ !~ m{^__ANON__} }
        @{ $pkg . '::__EXPORTABLES' };
    use strict;
    ## use critic

    return \%export;
}

sub _pkg_for {
    my $module_name = shift;

    return sprintf(
        'Local::%s::%s::%s::%s', __PACKAGE__, 'imported', $module_name,
        'implicit'
    );
}

1;

# ABSTRACT: A hack to try to figure out what a module exports

=pod

=head1 DESCRIPTION

Just try a generic implicit import and see what happens.

=head2 maybe_get_exports

    use App::perlimports::Importer::SubExporter ();

    my $exports
        = App::perlimports::Importer::SubExporter::maybe_get_exports(
        $module_name);

=cut
