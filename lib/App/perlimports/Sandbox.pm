package App::perlimports::Sandbox;

use strict;
use warnings;

our $VERSION = '0.000064';

use Data::UUID ();

{
    my $du = Data::UUID->new;

    sub pkg_for {
        my $module_name = shift;
        my $unique      = 'A' . $du->create_str;
        $unique =~ s{-}{}g;

        return sprintf(
            'Local::%s::%s',
            $module_name,
            $unique
        );
    }
}

sub eval_pkg {
    my $module_name = shift;
    my $content     = shift;

    my $pkg = pkg_for($module_name);

    my $to_eval = <<"EOF";
package $pkg;
$content;
1;
EOF

    ## no critic (Variables::RequireInitializationForLocalVars)
    local $@;

    # We only care about whether the eval throws an error. Trial-loading an
    # arbitrary module can emit the "Attempt to call undefined import method"
    # warning when a module has no import(), which we don't want to leak to
    # the user's terminal. We suppress only that specific noise and re-dispatch
    # anything else, so genuine diagnostics from a broken module still surface.
    my $prev_warn = $SIG{__WARN__};
    local $SIG{__WARN__} = sub {
        my ($msg) = @_;
        return if _is_trial_load_warning($msg);
        $prev_warn ? $prev_warn->($msg) : print {*STDERR} $msg;
    };
    ## no critic (BuiltinFunctions::ProhibitStringyEval,ErrorHandling::RequireCheckingReturnValueOfEval)
    eval $to_eval;

    my $e = $@;
    return $e;
}

# Recognize the noisy warning emitted when we trial-load a module that has no
# import() method. Perl's wording for this diagnostic changed from "undefined"
# to "missing" in the 5.44 development cycle, so match either variant.
sub _is_trial_load_warning {
    my $msg = shift;
    return defined $msg
        && $msg =~ m{Attempt to call (?:undefined|missing) import method};
}

1;

# ABSTRACT: Internal Tools for perlimports

=head2 pkg_for( $string )

Returns a random module/package name, which can be used to eval arbitrary code.
Requires the name of the module which will be imported into the package to be
created.

=head2 eval_pkg( $module_name, $pkg_content )

Takes a module name and content to eval. Returns the contents of C<$@>. So, if
it returns true, the C<eval> failed.

Returns a random module/package name, which can be used to eval arbitrary code.
Requires the name of the module which will be imported into the package to be
created.
