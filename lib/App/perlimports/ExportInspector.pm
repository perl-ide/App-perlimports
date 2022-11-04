package App::perlimports::ExportInspector;

use Moo;

## no critic (Modules::RequireExplicitInclusion, Subroutines::ProhibitCallsToUnexportedSubs, TestingAndDebugging::ProhibitNoStrict)

our $VERSION = '0.000050';

use App::perlimports::Sandbox ();
use Class::Inspector          ();
use List::Util                qw( any );
use Module::Runtime           qw( require_module );
use Sub::HandlesVia;
use Try::Tiny       qw( catch try );
use Types::Standard qw(ArrayRef Bool HashRef Int InstanceOf Str);

with 'App::perlimports::Role::Logger';

has at_export => (
    is          => 'ro',
    isa         => ArrayRef [Str],
    lazy        => 1,
    handles_via => 'Array',
    handles     => {
        has_at_export => 'count',
    },
    default => sub { shift->_implicit->{export} },
);

has at_export_ok => (
    is          => 'ro',
    isa         => ArrayRef [Str],
    lazy        => 1,
    handles_via => 'Array',
    handles     => {
        all_at_export_ok => 'elements',
        has_at_export_ok => 'count',
    },
    default => sub { shift->_implicit->{export_ok} },
);

has at_export_fail => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub { shift->_implicit->{export_fail} },
);

has at_export_tags => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub { shift->_implicit->{export_tags} },
);

has class_isa => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub { shift->_implicit->{class_isa} },
);

has has_fatal_error => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub { shift->_implicit->{fatal_error} ? 1 : 0 },
);

has _implicit => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_implicit',
);

has import_flags => (
    is          => 'ro',
    isa         => ArrayRef,
    lazy        => 1,
    handles_via => 'Array',
    handles     => {
        has_import_flags => 'count',
    },
    builder => '_build_import_flags',
);

has is_exporter => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_exporter',
);

has isa_test_builder => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_isa_test_builder',
);

has explicit_exports => (
    is          => 'ro',
    isa         => HashRef,
    lazy        => 1,
    handles_via => 'Hash',
    handles     => {
        has_explicit_exports   => 'count',
        explicit_export_names  => 'keys',
        explicit_export_values => 'values',
    },
    builder => '_build_explicit_exports',
);

has implicit_exports => (
    is          => 'ro',
    isa         => HashRef,
    lazy        => 1,
    handles_via => 'Hash',
    handles     => {
        has_implicit_exports   => 'count',
        implicit_export_names  => 'keys',
        implicit_export_values => 'values',
    },
    builder => '_build_implicit_exports',
);

sub _build_implicit_exports {
    my $self = shift;
    my $pkg  = $self->_pkg_for_implicit;
    return $self->is_exporter
        ? $self->_list_to_hash( $pkg, $self->at_export )
        : $self->_list_to_hash( $pkg, $self->_implicit->{_maybe_exports} );
}

has is_moose_class => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_moose_class',
);

has is_moo_class => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_moo_class',
);

has is_moose_type_class => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_moose_type_class',
);

has is_oo_class => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_oo_class',
);

has _module_name => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'module_name',
    required => 1,
);

has pkg_isa => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub {
        no strict 'refs';
        return [ @{ shift->_pkg_for_implicit . '::ISA' } ];
    },
);

has _pkg_for_implicit => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { return shift()->_random_pkg_name },
);

has success_counter => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => Int,
    default => 0,
    handles => {
        _increment_success_counter => 'inc',
    },
);

has uses_moose => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_uses_moose',
);

sub evals_ok {
    my $self = shift;

    $self->explicit_exports;
    $self->implicit_exports;
    return $self->success_counter;
}

sub _build_explicit_exports {
    my $self = shift;

    # If this is Exporter, then the exportable symbols will be listed in either
    # @EXPORT or @EXPORT_OK. Maybe in both?
    if ( $self->has_at_export_ok || $self->has_at_export ) {
        return $self->_list_to_hash(
            $self->_pkg_for_implicit,    # reuse package name
            [ @{ $self->at_export }, @{ $self->at_export_ok } ]
        );
    }

    # If this is Sub::Exporter, we can cheat and see what's in the :all tag
    my $pkg           = $self->_random_pkg_name;
    my $use_statement = sprintf( 'use %s qw(:all);', $self->_module_name );
    my ($exports)     = $self->_exports_for_include( $pkg, $use_statement );
    return $self->_list_to_hash( $pkg, $exports );

    # If this module uses something other than Exporter or Sub::Exporter, we
    # probably returned an empty hash above.  We could guess and say it's the
    # default exports + possibly something else.  It's probably less confusing
    # to leave it up to the code which uses this object to decide how to handle
    # it.
}

sub _build_import_flags {
    my $self = shift;

    my %modules = (
        Carp    => ['verbose'],
        English => ['-no_match_vars'],
    );

    return
        exists $modules{ $self->_module_name }
        ? $modules{ $self->_module_name }
        : [];
}

sub _build_is_exporter {
    my $self = shift;

    return 1 if any { $_ eq 'Exporter' } @{ $self->class_isa };
    return $self->has_at_export || $self->has_at_export_ok ? 1 : 0;
}

sub _build_is_oo_class {
    my $self = shift;

    return 0 if $self->has_implicit_exports || $self->has_explicit_exports;

    my $methods
        = Class::Inspector->methods( $self->_module_name, 'full', 'public' );

    return any {
        $_ eq 'Moose::Object::BUILDALL' || $_ eq 'Moo::Object::BUILDALL'
    } @{$methods};
}

sub _build_isa_test_builder {
    my $self = shift;
    if ( any { $_ eq 'Test::Builder::Module' }
        @{ $self->_implicit->{class_isa} } ) {
        return 1;
    }

    return 0 if $self->_module_name !~ m{\ATest};

    my $err = App::perlimports::Sandbox::eval_pkg(
        $self->_module_name,
        sprintf( 'use %s qw( some_function );', $self->_module_name )
    );

    # Catch cases like Test::HTML::Lint, where, which doesn't subclass
    # Test::Builder, but essentially calls Tester::Builder->new->plan(@_); in
    # its import(). The error will be something like "plan() doesn't understand
    # some_function at"
    if ( $err =~ m{plan} ) {
        return 1;
    }
    return 0;
}

sub _list_to_hash {
    my $self = shift;
    my $pkg  = shift;
    my $list = shift;

    my %hash;
    for my $item ( @{$list} ) {
        my $value = $item;
        $value =~ s{^&}{};
        $hash{$item} = $value;
    }

    # Specifically for File::chdir, which exports a typeglob, but doesn't
    # implement every possibility.
    for my $key ( keys %hash ) {
        if ( substr( $key, 0, 1 ) eq '*' ) {
            my $thing = substr( $key, 1 );
            for my $sigil ( '&', '$', '@', '%' ) {
                my $symbol_name = $sigil . $pkg . '::' . $thing;
                if ( Symbol::Get::get($symbol_name) ) {
                    $hash{ $sigil . $thing } = $key;
                }
            }
        }
    }

    # Treat Moose type libraries a bit differently. Importing ArrayRef, for
    # instance, also imports is_ArrayRef and to_ArrayRef (if a coercion)
    # exists. So, let's deal with that here.
    if ( $self->is_moose_type_class ) {
        for my $key ( keys %hash ) {
            if ( $key =~ m{^(is_|to_)} ) {
                $hash{$key} = substr( $key, 3 );
            }
        }
    }

    return \%hash;
}

sub _build_implicit {
    my $self = shift;

    my $module_name   = $self->_module_name;
    my $pkg           = $self->_pkg_for_implicit;
    my $use_statement = "use $module_name;";
    my ( $maybe_exports, $fatal_error )
        = $self->_exports_for_include( $pkg, $use_statement );

    no strict 'refs';
    my $aggregated = {
        class_isa      => [ @{ $self->_module_name . '::ISA' } ],
        export         => [ @{ $self->_module_name . '::EXPORT' } ],
        export_fail    => [ @{ $self->_module_name . '::EXPORT_FAIL' } ],
        export_ok      => [ @{ $self->_module_name . '::EXPORT_OK' } ],
        export_tags    => [ @{ $self->_module_name . '::EXPORT_TAGS' } ],
        fatal_error    => $fatal_error,
        _maybe_exports => $maybe_exports,
    };

    return $aggregated;
}

sub _exports_for_include {
    my $self          = shift;
    my $pkg           = shift;
    my $use_statement = shift;

    my $logger = $self->logger;

    # If you're importing Moose into a namespace and following that with an
    # import of namespace::autoclean, you may find that symbols like "after"
    # and "around" are no longer found.
    #
    # We log available symbols inside the BEGIN block in order to defeat
    # namespace::autoclean, which removes symbols from the stash after
    # compilation but before runtime. Thanks to Florian Ragwitz for the tip and
    # the preceding explanation.

    my $to_eval = <<"EOF";
package $pkg;

use Symbol::Get;
$use_statement
our \@__EXPORTABLES;

BEGIN {
    \@__EXPORTABLES = Symbol::Get::get_names();
}
1;
EOF

    $self->logger->debug($to_eval);

    my $logger_cb = sub {
        my $msg   = shift;
        my $level = 'info';

        # Mojo classes tend to throw "Can't locate :all.pm in @INC". This is
        # expected and shouldn't be raised to the warning level.
        if ( $msg =~ qr{Can't locate} && $msg !~ m{\:all\.pm in \@INC} ) {
            $level = 'warning';
        }

        $logger->log(
            level   => $level,
            message => sprintf(
                "Problem trying to eval %s\n%s",
                $pkg,
                $msg,
            ),
        );
    };

    local $SIG{__WARN__} = $logger_cb;

    local $@ = undef;
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval $to_eval;

    if ($@) {
        $logger_cb->($@);
        return undef, $@;
    }
    else {
        $self->_increment_success_counter;
    }

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    my @export
        = grep { $_ !~ m{(?:BEGIN|ISA|__EXPORTABLES)} && $_ !~ m{^__ANON__} }
        @{ $pkg . '::__EXPORTABLES' };
    use strict;
    ## use critic

    return \@export, undef;
}

sub _random_pkg_name {
    my $self = shift;
    return App::perlimports::Sandbox::pkg_for( $self->_module_name );
}

sub _build_is_moose_class {
    my $self = shift;

    return
        any { $_ eq 'Moose::Object' || $_ eq 'Test::Class::Moose' }
        @{ $self->pkg_isa };
}

sub _build_uses_moose {
    my $self = shift;
    if ( $self->_maybe_require_module('Moose::Util') ) {
        return Moose::Util::find_meta( $self->_module_name ) ? 1 : 0;
    }
    return 0;
}

sub _build_is_moo_class {
    my $self = shift;
    if ( $self->_maybe_require_module('Class::Inspector') ) {
        return 1
            if any { $_ eq 'Moo::is_class' } @{ Class::Inspector->methods(
                $self->_module_name, 'full', 'public'
                )
                || []
            };
    }
    return 0;
}

sub _build_is_moose_type_class {
    my $self = shift;

    return
        any { $_ eq 'MooseX::Types::Base' || $_ eq 'MooseX::Types::Combine' }
        @{ $self->class_isa };
}

sub explicit_export_names_match_values {
    my $self = shift;
    return
        join( q{}, sort $self->explicit_export_names ) eq
        join( q{}, sort $self->explicit_export_values );
}

sub implicit_export_names_match_values {
    my $self = shift;
    return
        join( q{}, sort $self->implicit_export_names ) eq
        join( q{}, sort $self->implicit_export_values );
}

sub _maybe_require_module {
    my $self              = shift;
    my $module_to_require = shift;

    $self->logger->info("going to require $module_to_require");

    my $success;
    try {
        require_module($module_to_require);
        $success = 1;
    }
    catch {
        $self->logger->info("$module_to_require error. $_");
    };

    return $success;
}

1;

# ABSTRACT: Inspect code for exportable symbols

=pod

=head1 DESCRIPTION

Inspect modules to see what they might export.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use App::perlimport::ExportInspector ();

    my $ei = App::perlimport::ExportInspector->new(
        module_name => 'Carp',
    );

    my $exports = $ei->explicit_exports;

=head1 MOTIVATION

Since we're (maybe) importing symbols as part of this process, we've sandboxed
it a little bit by not doing it in L<App::perlimports> directly.

=head1 METHODS

The following methods are available.

=head2 implicit_exports

A HashRef with keys representing symbols which a module implicitly exports
(i.e.  via C<use Module::Name;>. The values represent the import value which
you would need in order to explicitly import the symbol. Often these will be
the same, but there are exceptions. For example, a type library may export
C<is_ArrayRef>, but you import it via C<use My::Type::Library qw( ArrayRef );>.

=head2 explicit_exports

A HashRef with keys representing symbols which a module explicitly exports
(i.e.  via C<use Module::Name qw( foo bar );>. The values represent the import
value which you would need in order to explicitly import the symbol. Often
these will be the same, but there are exceptions. For example, a type library
may export C<is_ArrayRef>, but you import it via C<use My::Type::Library qw(
ArrayRef );>.

In cases where we cannot be certain about the explicit exports, you can try to
fall back to the implicit exports to get an idea of what this module can
export.

=head2 evals_ok

Returns true if either implicit or explicit exports can be built without
setting C<$@>.

=head2 implicit_export_names_match_values

Returns true if the keys and values in C<implicit_exports> match.

=head2 explicit_export_names_match_values

Returns true if the keys and values in C<explicit_exports> match.

=head2 success_counter

Returns an integer representing the number of times we were able to execute
eval statements for this package which did not pollute C<$@>.

=head1 CAVEATS

This may not work with modules using some creative way of managing symbol
exports.

=cut
