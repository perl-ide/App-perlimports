package App::perlimports::Include;

use Moo;

our $VERSION = '0.000059';

## no critic (Bangs::ProhibitDebuggingModules)

use Data::Dumper qw( Dumper );
use List::Util   qw( any none uniq );
use Memoize      qw( flush_cache memoize );
use MooX::StrictConstructor;
use PPI::Document               ();
use PPIx::Utils::Classification qw( is_function_call is_perl_builtin );
use Ref::Util                   qw( is_plain_arrayref is_plain_hashref );
use Sub::HandlesVia;
use Try::Tiny       qw( catch try );
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Maybe Object Str);

with 'App::perlimports::Role::Logger';

memoize('is_function_call');

sub BUILD {
    flush_cache('is_function_call');
}

# this is a catalog of the @EXPORT's of the target module,
# or @EXPORT_OK, or else whatever comes from "use Module;"
has _explicit_exports => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        _delete_export         => 'delete',
        _explicit_export_count => 'count',
        _has_explicit_exports  => 'count',
        _import_name           => 'get',
        _is_importable         => 'exists',
    },
    lazy    => 1,
    builder => '_build_explicit_exports',
);

has _document => (
    is       => 'ro',
    isa      => InstanceOf ['App::perlimports::Document'],
    required => 1,
    init_arg => 'document',
);

has _export_inspector => (
    is        => 'ro',
    isa       => InstanceOf ['App::perlimports::ExportInspector'],
    predicate => '_has_export_inspector',     # used in test
    lazy      => 1,
    builder   => '_build_export_inspector',
);

has formatted_ppi_statement => (
    is      => 'ro',
    isa     => InstanceOf ['PPI::Statement::Include'],
    lazy    => 1,
    builder => '_build_formatted_ppi_statement',
);

has _ignored_modules => (
    is        => 'ro',
    isa       => ArrayRef,
    init_arg  => 'ignored_modules',
    predicate => '_has_ignored_modules',
);

has _imports => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_imports',
);

has _include => (
    is       => 'ro',
    isa      => InstanceOf ['PPI::Statement::Include'],
    init_arg => 'include',
    required => 1,
);

has _is_ignored => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_ignored',
);

has _isa_test_builder_module => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub { shift->_export_inspector->isa_test_builder },
);

has _is_translatable => (
    is            => 'ro',
    isa           => Bool,
    lazy          => 1,
    builder       => '_build_is_translatable',
    documentation => 'Is this a require which can be converted to a use?',
);

has module_name => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    default => sub { shift->_include->module },
);

has _found_imports => (
    is          => 'ro',
    isa         => Maybe [ArrayRef],
    init_arg    => 'found_imports',
    handles_via => 'Array',
    handles     => {
        _all_found_imports => 'elements',
        _has_found_imports => 'count',
    },
);

has _pad_imports => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'pad_imports',
    default  => sub { 1 },
);

has _tidy_whitespace => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'tidy_whitespace',
    lazy     => 1,
    default  => sub { 1 },
);

has _will_never_export => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return exists $self->_document->never_exports->{ $self->module_name }
            || $self->_export_inspector->is_oo_class;
    },
);

sub _build_export_inspector {
    my $self = shift;
    return $self->_document->inspector_for( $self->module_name );
}

# If we have implicit (but not explicit) exports,  we will make a best guess at
# what gets exported by using the implicit list.
sub _build_explicit_exports {
    my $self = shift;
    return $self->_export_inspector->has_explicit_exports
        ? $self->_export_inspector->explicit_exports
        : $self->_export_inspector->implicit_exports;
}

## no critic (Subroutines::ProhibitExcessComplexity)
sub _build_imports {
    my $self = shift;

    # This is not a real symbol, so we should never be looking for it to appear
    # in the code.
    $self->_delete_export('verbose') if $self->module_name eq 'Carp';

    my %found;

    # Stolen from Perl::Critic::Policy::TooMuchCode::ProhibitUnfoundImport
    for my $word ( @{ $self->_document->possible_imports } ) {
        next if exists $found{"$word"};

        # stop if we've found everything that can be imported (every
        # possible exported symbol is being used)
        last unless $self->_imports_remain( \%found );

        # We don't want (for instance) pragma names to be confused with
        # functions.
        #
        # ie:
        # use warnings;
        # use Test::Warnings; # exports warnings()
        #
        # However, we also want to catch function calls in use statements, like
        # "use lib catfile( 't', 'lib');"
        #
        # or
        #
        # use Mojo::File qw( curfile );
        # use lib curfile->sibling('lib')->to_string;
        my $is_function_call = is_function_call($word);
        if (
               $word->parent
            && $word->parent->isa('PPI::Statement::Include')
            && (   !$is_function_call
                && !( $word->snext_sibling && $word->snext_sibling eq '->' ) )
        ) {
            next;
        }

        # Don't turn "use POSIX ();" into "use POSIX qw( sprintf );"
        # If it's a function and it's a builtin function and it's either not
        # included in found_imports or original imports are not implicit
        # then skip this.
        if (   defined $self->_found_imports
            && ( none { $_ eq $word } @{ $self->_found_imports } )
            && $is_function_call
            && is_perl_builtin($word) ) {
            next;
        }

        my @found_import;
        my $isa_symbol = $word->isa('PPI::Token::Symbol');

        # Don't confuse my @Foo with a use of @Foo which is exported by a module.
        if ( $isa_symbol && $word->content =~ m{\A(@|%|$)} ) {
            my $previous_sibling = $word->sprevious_sibling;
            if ( $previous_sibling && $previous_sibling->content eq 'my' ) {
                next;
            }
        }

        # If a module exports %foo and we find $foo{bar}, $word->canonical
        # returns $foo and $word->symbol returns %foo
        if (   $isa_symbol
            && $self->_is_importable( $word->symbol ) ) {
            @found_import = ( $word->symbol );
        }

        # Match on \&is_Str as is_Str
        elsif ($isa_symbol
            && $word->symbol_type eq '&'
            && $self->_is_importable( substr( $word->symbol, 1 ) ) ) {
            @found_import = ( substr( $word->symbol, 1 ) );
        }

        # Don't catch ${foo} here and mistake it for "foo". We deal with that
        # elsewhere. Don't catch @{ split_header $str }.
        elsif (
            $self->_is_importable("$word")
            && !(
                   $word =~ m{^\w}
                && $word->previous_token
                && $word->previous_token eq '{'
                && $word->previous_token->previous_token
                && $word->previous_token->previous_token eq '$'
            )
        ) {
            @found_import = ("$word");
        }

        # Maybe a subroutine ref has been exported. For instance,
        # Getopt::Long exports &GetOptions
        elsif ($is_function_call
            && $self->_is_importable( '&' . $word ) ) {
            @found_import = ( '&' . "$word" );
        }

        # Maybe this is an inner package referencing a function in main.  We
        # don't really deal with inner packages otherwise, so this could break
        # some things.
        elsif ($is_function_call
            && $word =~ m{^::\w+}
            && $self->_is_importable( substr( $word, 2 ) ) ) {
            @found_import = ( substr( $word, 2 ) );
        }

        # PPI can think that an imported function in a ternary is a label
        # my $foo = $enabled ? GEOIP_MEMORY_CACHE : 0;
        # The content of the $word will be "GEOIP_MEMORY_CACHE :"
        elsif ( $word->isa('PPI::Token::Label') ) {
            if ( $word->content =~ m{^(\w+)} ) {
                my $label = $1;
                if ( $self->_is_importable($label) ) {
                    @found_import = ($label);
                    $found{$label}++;
                }
            }
        }

        # Sometimes an import is only used to set a default value for a
        # variable in a signature. Without treating a prototype as a signature,
        # we would miss the import entirely.  I'm not particularly proud of
        # this, but since PPI doesn't yet support signatures, this will at
        # least help us cover some cases. If the prototype is actually a
        # prototype, then this just shouldn't find anything.
        elsif ( $word->isa('PPI::Token::Prototype') ) {
            my $prototype = $word->prototype;

            # sometimes closing parens don't get included by PPI.
            if ( substr( $prototype, -1, 1 ) eq '(' ) {
                $prototype .= ')';
            }
            $prototype =~ s{,}{;}g;

            $prototype .= ';';    # Won't hurt if there's an extra ";"
            my $new   = PPI::Document->new( \$prototype );
            my $words = $new->find(
                sub {
                    $_[1]->isa('PPI::Token::Word')
                        || $_[1]->isa('PPI::Token::Symbol');
                }
            ) || [];
            for my $word ( @{$words} ) {
                if ( $self->_is_importable("$word") ) {
                    push @found_import, "$word";
                }
            }
        }

        for my $found (@found_import) {

            # could have been imported by another Include
            if ( !$self->_is_already_imported($found) ) {
                $found{$found}++;
            }
        }
    }

    #  A used import might be a variable interpolated into quotes.
    if ( $self->_imports_remain( \%found ) ) {
        for my $var ( keys %{ $self->_document->interpolated_symbols } ) {
            if ( $self->_is_importable($var) ) {
                $found{$var} = 1;
            }
        }
    }

    #  A used import might be just be a symbol that just gets exported.  ie. If
    #  it appears as @EXPORT = ( 'SOME_SYMBOL') we don't want to miss it.
    if (   $self->_imports_remain( \%found )
        && $self->_document->my_own_inspector
        && $self->_document->my_own_inspector->is_exporter ) {
        for my $symbol (
            uniq(
                $self->_document->my_own_inspector->implicit_export_names,
                $self->_document->my_own_inspector->explicit_export_names
            )
        ) {
            if ( $self->_is_importable($symbol)
                && !$self->_document->is_sub_name("$symbol") ) {
                $found{$symbol} = 1;
            }
        }
    }

    # A used import might just be something that gets re-exported by
    # Sub::Exporter
    if ( $self->_imports_remain( \%found ) ) {
        for my $func ( $self->_document->sub_exporter_export_list ) {
            if ( $self->_is_importable($func) ) {
                $found{$func}++;
            }
        }
    }

    my @found = map { $self->_import_name($_) } keys %found;

    # Some modules have imports which are basically flags, rather than names of
    # symbols to export.  So if a flag is already in the import, we need to
    # preserve it, rather than risk altering the behaviour of the module.
    if ( $self->_export_inspector->has_import_flags ) {
        for my $arg ( @{ $self->_export_inspector->import_flags } ) {
            if ( defined $self->_found_imports
                && ( any { $_ eq $arg } @{ $self->_found_imports } ) ) {
                push @found, $arg;
            }
        }
    }

    @found = uniq _sort_symbols(@found);
    if ( $self->_found_imports ) {
        my @preserved = grep { m{\A[!_]} } @{ $self->_found_imports };
        @found = uniq( @preserved, @found );
    }
    return \@found;
}

## use critic

sub _build_is_ignored {
    my $self = shift;

    if ( $self->_include->type eq 'require' ) {
        return 1 if !$self->_is_translatable;
    }

    # This will be rewritten as "use Foo ();"
    return 0 if $self->_will_never_export;

    return 1 if $self->_export_inspector->has_fatal_error;

    return 0 if $self->_export_inspector->is_oo_class;

    return 1 if $self->_export_inspector->is_moose_class;

    return 1 if $self->_export_inspector->uses_moose;

    return 1 if $self->_export_inspector->is_moo_class;

    return 1
        if any { $_ eq 'Moo::Object' } @{ $self->_export_inspector->pkg_isa };

    return 0;
}

sub _build_is_translatable {
    my $self = shift;

    return 0 if !$self->_include->type;
    return 0 if $self->_include->type ne 'require';
    return 0 if $self->module_name eq 'Exporter';

    # We can deal with a top level require.
    # require Foo; can be changed to use Foo ();
    # We don't want to touch requires which are inside any kind of a condition.

    # If there is no parent, then it's likely just a single snippet
    # provided by a text editor. We can process the snippet. If it's part
    # of a larger document and the parent is not a PPI::Document, this
    # would appear not to be a top level require.
    if ( $self->_include->parent
        && !$self->_include->parent->isa('PPI::Document') ) {
        return 0;
    }

    # Postfix conditions are a bit harder to find. If the significant
    # children amount to more than "require Module;", we'll just move on.
    my @children = $self->_include->schildren;

    my $statement = join q{ }, @children[ 0 .. 2 ];
    if ( $statement ne 'require ' . $self->module_name . ' ;' ) {
        return 0;
    }

    # Any other case of "require Foo;" should be translated to "use Foo ();"
    # as those are functionally equivalent.
    return 1;
}

## no critic (Subroutines::ProhibitExcessComplexity)
sub _build_formatted_ppi_statement {
    my $self = shift;

    # The following steps may seem a bit out of order, but we're trying to
    # short circuit if at all possible. That means not building an
    # ExportInspector object unless we really need to.

    # Nothing to do here. Preserve the original statement.
    return $self->_include if $self->_is_ignored;

    my $maybe_module_version
        = $self->_include->module_version
        ? q{ } . $self->_include->module_version
        : q{};

    # In this case we either have a module which we know will never export
    # symbols or a module which can export but for which we haven't found any
    # imported symbols. In both cases we'll want to rewrite with an empty list
    # of imports.
    if (   $self->_will_never_export
        || $self->_is_translatable
        || !@{ $self->_imports } ) {
        return $self->_maybe_get_new_include(
            sprintf(
                'use %s%s ();', $self->module_name, $maybe_module_version
            )
        );
    }

    my $statement;

    my @args = $self->_include->arguments;

    # Don't touch a do { } block.
    if ( $self->_isa_test_builder_module && @args && $args[0] eq 'do' ) {
        return $self->_include;
    }

    # Do some contortions to turn PPI objects back into a data structure so
    # that we can add or replace an import hash key and then end up with a new
    # list which is sorted on hash keys. This makes the assumption that the
    # same key won't get passed twice. This is pretty gross, but I was too lazy
    # to try to figure out how to do this with PPI and I think it should
    # *mostly* work. I don't like the formatting that Data::Dumper comes up
    # with, so we'll run it through perltidy.

    if (   $self->_isa_test_builder_module
        && @args ) {
        my $all;

        if ( $args[0]->isa('PPI::Token::Word') ) {
            $all = join q{ }, map { "$_" } @args;
        }

        elsif ($args[0]->isa('PPI::Structure::List')
            && $args[0]->braces eq '()' ) {
            for my $child ( $args[0]->children ) {
                $all .= "$child";
            }
        }

        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        my $args;
        my $error;
        try {
            $args = eval( '{' . $all . '}' );
        }
        catch {
            $self->logger->info($_);
            $error = 1;
        };
        ## use critic

        if ( !$error && !is_plain_hashref($args) ) {
            $self->logger->info( 'Not a hashref: ' . Dumper($args) );
            $error = 1;
        }

        # We will replace these with our own parsed imports.
        delete $args->{import};

        # Ignore this line if we can't parse it. This will happen if the arg to
        # test is a do block, for example.
        return $self->_include if $error;

        local $Data::Dumper::Terse         = 1;
        local $Data::Dumper::Indent        = 0;
        local $Data::Dumper::Sortkeys      = 1;
        local $Data::Dumper::Quotekeys     = 0;
        local $Data::Dumper::Useqq         = 0;
        local $Data::Dumper::Trailingcomma = 1;
        local $Data::Dumper::Deparse       = 1;

        my $dumped = Dumper($args);
        my $non_import_args;
        my $import_arg;

        if ( $dumped =~ m/^{(.*)}$/ ) {
            $non_import_args = $1;
        }

        if ( $self->_imports ) {
            $import_arg = sprintf(
                'import => [qw( %s )]',
                join( q{ }, @{ $self->_imports } )
            );
        }

        my $all_args = join ', ',
            grep { $_ && $_ =~ m{\w} } ( $import_arg, $non_import_args );

        $statement = sprintf(
            'use %s%s %s;',
            $self->module_name,
            $maybe_module_version,
            $all_args
        );

        # save ~60ms in cases where we don't need Perl::Tidy
        require Perl::Tidy;    ## no perlimports
        Perl::Tidy::perltidy(
            argv        => '-npro',
            source      => \$statement,
            destination => \$statement
        );
    }

    else {
        my $padding = $self->_pad_imports ? q{ } : q{};
        my $template
            = $self->_isa_test_builder_module
            ? 'use %s%s import => [ qw(%s%s%s) ];'
            : 'use %s%s qw(%s%s%s);';

        $statement = sprintf(
            $template,
            $self->module_name,
            $maybe_module_version,
            $padding,
            join(
                q{ },
                @{ $self->_imports }
            ),
            $padding,
        );
    }

    # Don't deal with Test::Builder classes here to keep it simple for now
    if ( length($statement) > 78 && !$self->_isa_test_builder_module ) {
        $statement = sprintf(
            "use %s%s qw(\n",
            $self->module_name,
            $maybe_module_version,
        );
        for ( @{ $self->_imports } ) {
            $statement .= "    $_\n";
        }
        $statement .= ');';
    }

    return $self->_maybe_get_new_include($statement);
}

## use critic

sub _imports_remain {
    my $self  = shift;
    my $found = shift;
    return keys %{$found} < $self->_explicit_export_count;
}

# Takes a string 'use SomeModule ...', returns a PPI:Statement:Include.
# The returned obj could be one made from the string, if its different from
# the existing one, else it is just the original.
sub _maybe_get_new_include {
    my $self      = shift;
    my $statement = shift;
    my $orig      = $self->_include;
    return $orig if $statement eq $orig;    # quick exit

    # Prefix newlines to reproduce original's location
    ## no critic (BuiltinFunctions::ProhibitLvalueSubstr)
    my $doc = do {
        my $line = $orig->line_number || 1;
        my $text = "\n" x $line;
        substr( $text, -1 ) = $statement;
        PPI::Document->new( \$text, filename => $orig->logical_filename );
    };
    ## use critic

    # Cloning is necessary because the tokens in the found statement belong
    # to the document. When the document is destroyed, the tokens go with it.
    # With the clone, the duplicated tokens are independent of the doc.
    my $rewrite = do {
        $doc->index_locations;
        my $includes = $doc->find('Statement::Include');
        $includes->[0]->clone;
    };

    # If the -only- difference is some whitespace before the symbol list, we
    # keep the original statement. This is because perltidy often adds space
    # to align successive import lists, and we don't want to fight. So:
    #    use AAAAAAA qw( thing );
    #    use Foo     qw( bar );     <== leave this spacing alone

    # strip away extra spaces before the symbol list..
    my $untidied_include = do {
        my $string = "$orig";
        $string =~ s{\s+(qw|\()}{ $1};
        $string;
    };
    if ( "$rewrite" eq $untidied_include ) {
        return $orig;
    }

    return $rewrite if $self->_tidy_whitespace;

    # We will return the rewritten include if a newline has been added or
    # removed. This is a formatting change that we *probably* want.

    ( my $a = $orig . q{} )    =~ s{\s+}{}g;
    ( my $b = $rewrite . q{} ) =~ s{\s+}{}g;

    return ( $a eq $b ) ? $orig : $rewrite;
}

# If there's a different module in this document which has already imported
# a symbol of the same name in its original imports, the we should make
# sure we don't accidentally create a duplicate import here. For example,
# Path::Tiny and Test::TempDir::Tiny both export a tempdir() function.
# Without this check we'd add a "tempdir" to both modules if we find it
# being used in the document.

sub _is_already_imported {
    my $self      = shift;
    my $symbol    = shift;
    my $duplicate = 0;

    foreach my $module (
        grep { $_ ne $self->module_name }
        keys %{ $self->_document->found_imports }
    ) {
        $self->logger->debug(
            "checking $module for previous imports of $symbol");
        my @imports;
        if ( is_plain_arrayref( $self->_document->found_imports->{$module} ) )
        {
            @imports = @{ $self->_document->found_imports->{$module} };
            $self->logger->debug(
                'Explicit imports found: ' . Dumper( [ sort @imports ] ) );
        }
        else {
            if ( my $inspector = $self->_document->inspector_for($module) ) {
                @imports = $inspector->implicit_export_names;
                $self->logger->debug( 'Implicit imports found: '
                        . Dumper( [ sort @imports ] ) );
            }
        }

        if ( any { $_ eq $symbol } @imports ) {
            $duplicate = 1;
            $self->logger->debug("$symbol already imported via $module");
            last;
        }
    }

    return $duplicate;
}

sub _sort_symbols {
    my @list = @_;

    ## no critic (BuiltinFunctions::RequireSimpleSortBlock)
    my @sorted = sort {
        my $A = _transform_before_cmp($a);
        my $B = _transform_before_cmp($b);
        "\L$A" cmp "\L$B";
    } @list;
    return @sorted;
}

# This looks a little weird, but basically we want to maintain a stable sort
# order with lists that look like (foo, $foo, @foo, %foo). We use "-" to begin
# the suffix because it comes earliest in a sorted list of letters and digits.
sub _transform_before_cmp {
    my $thing = shift;
    if ( $thing =~ m{\A[\$]} ) {
        $thing = substr( $thing, 1 ) . '-0';
    }
    elsif ( $thing =~ m{\A[@]} ) {
        $thing = substr( $thing, 1 ) . '-1';
    }
    elsif ( $thing =~ m{\A[%]} ) {
        $thing = substr( $thing, 1 ) . '-2';
    }
    return $thing;
}

1;

# ABSTRACT: Encapsulate one use statement in a document

=pod

=head1 METHODS

=head2 formatted_ppi_statement

Returns an L<PPI::Statement::Include> object. This can be stringified into an
import statement or used to replace an existing L<PPI::Statement::Include>.

=cut
