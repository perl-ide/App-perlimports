package App::perlimports;

use strict;
use warnings;

our $VERSION = '0.000016';

1;

# ABSTRACT: Make implicit imports explicit

=pod

=head1 DESCRIPTION

This distribution provides the L<perlimports> binary, which aims to automate
the cleanup and maintenance of Perl import statements.

=head1 SYNOPSIS

Update a file in place. (Make sure you can revert the file if you need to.)

    perlimports --filename test-data/foo.pl --inplace-edit

If some of your imported modules are in local directories, you can give some
hints as to where to find them:

    perlimports --filename test-data/foo.pl --inplace-edit --libs t/lib,/some/dir/lib

Redirect output to a new file:

    perlimports --filename test-data/foo.pl > foo.new.pl

=head2 COMMAND LINE INTERFACE

See L<perlimports> for more complete documentation of the command line
interface.

=head2 ANNOTATIONS/IGNORING MODULES

Aside from the documented command line switches for ignoring modules, you can
add annotations in your code.

    use Encode; ## no perlimports

The above will tell L<perlimports> not to attempt a tidy of this line.

    ## no perlimports
    use Encode;
    use Cpanel::JSON::XS;
    ## use perlimports

    use POSIX ();

The above will tell L<perlimports> not to tidy the two modules contained inside
of the annotations.

Please note that since L<perlimports> needs to know as much as possible about
what's going on in a file, the annotations don't prevent modules from being
loaded. It's only a directive to leave the lines in the file unchanged after
processing.

=head2 VIM

If you're a C<vim> user, you can pipe your import statements to L<perlimports> directly.

    :vnoremap <silent> im :!perlimports --read-stdin --filename '%:p'<CR>

The above statement will allow you to visually select one or more lines of code
and have them updated in place by L<perlimports>. Once you have selected the
code enter C<im> to have your imports (re)formatted.

=head2 MOTIVATION

Many Perl modules helpfully export functions and variables by default. These
provide handy shortcuts when you're writing a quick or small script, but they
can quickly become a maintenance burden as code grows organically. When code
increases in complexity, it leads to greater costs in terms of development time.
Conversely, reducing code complexity can speed up development. This tool aims
to reduce complexity to further this goal.

While importing symbols by default or using export tags provides a convenient
shorthand for getting work done, this shorthand requires the developer to
retain knowledge of these defaults and tags in order to understand the code.
C<perlimports> aims to allow you to develop your code as you see fit, while
still giving you a viable option of tidying your imports automatically. In much
the same way as you might use L<perltidy> to format your code, you can now
automate the process of making your imports easier to understand. Let's look at
some examples.

=over

=item Where is this function defined?

You may come across some code like this:

    use strict;
    use warnings;

    use HTTP::Request::Common;
    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new;
    my $req = $ua->request( GET 'https://metacpan.org/' );
    print $req->content;

Where does C<GET> come from? If you're not familiar with
L<HTTP::Request::Common>, you may not realize that the statement C<use
HTTP::Request::Common> has implicitly imported the functions C<GET>, C<HEAD>,
C<PUT>, C<PATCH>, C<POST> and C<OPTIONS> into to this block of code.

What would happen if we used C<perlimports> to import all needed functions
explicitly? It might look something like this:

    use strict;
    use warnings;

    use HTTP::Request::Common qw( GET );
    use LWP::UserAgent ();

    my $ua = LWP::UserAgent->new;
    my $req = $ua->request( GET 'https://metacpan.org/' );
    print $req->content;

The code above makes it immediately obvious where C<GET> originates, which in
turn makes it easier for us to look up its documentation. It has the added
bonus of also not importing C<HEAD>, C<PUT> or any of the other functions which
L<HTTP::Request::Common> exports by default. So, those functions cannot
unwittingly be used later in the code. This makes for more understandable code
for present day you, future you and any others tasked with reading your code at
some future point.

Keep in mind that this simple act can save much time for developers who are not
intimately familiar with Perl and the default exports of many CPAN modules.

=item Are we even using all of these imports?

Imagine the following import statement

    use HTTP::Status qw(
        is_cacheable_by_default
        is_client_error
        is_error
        is_info
        is_redirect
        is_server_error
        is_success
        status_message
    );

followed by 3,000 lines of code. How do you know if all of these functions are
actually being used? Were they ever used? You can grep all of these function
names manually or you can remove them by trial and error to see what breaks.
This is a doable solution, but it does not scale well to scripts and modules
with many imports or to large code bases with many imports. Having an
unmaintained list of imports is preferable to implicit imports, but it would be
helpful to automate maintaining this list.

L<perlimports> can, in many situations, clean up your import statements and
automate this maintenance burden away. This makes it easier for you to write
clean code, which is easier to understand.

=item Are we even using all of these modules?

In cases where code is implicitly importing from modules or where explicit
imports are not being curated, it can be hard to discover which modules are no
longer being used in a script, module or even a code base. Removing unused
modules from code can lead to gains in performance and decrease in consumption
of resources. Removing entire modules from your code base can decrease the
number of dependencies which you need to manage and decrease friction in your
your deployment process.

C<perlimports> does not remove unused modules for you, but using it to actively
tidy your imports can make this manual process much easier to manage.

=item Enforcing a consistent style

Having a messy list of module imports makes your code harder to read. Imagine
this:

    use Cpanel::JSON::XS;
    use Database::Migrator::Types qw( HashRef ArrayRef Object Str Bool Maybe CodeRef FileHandle RegexpRef );
    use List::AllUtils qw( uniq any );
    use LWP::UserAgent    q{};
    use Try::Tiny qw/ catch     try /;
    use WWW::Mechanize  q<>;

L<perlimports> turns the above list into:

    use Cpanel::JSON::XS ();
    use Database::Migrator::Types qw(
        ArrayRef
        Bool
        CodeRef
        FileHandle
        HashRef
        Maybe
        Object
        RegexpRef
        Str
    );
    use List::AllUtils qw( any uniq );
    use LWP::UserAgent ();
    use Try::Tiny qw( catch try);
    use WWW::Mechanize ();

Where possible, L<perlimports> will enforce a consistent style of parentheses
and will also sort your imports and break up long lines. As mentioned above, if
some imports are no longer in use, C<perlimports> will helpfully remove these
for you.

=item Import tags

Import tags may obscure where symbols are coming from. While import tags
provide a useful shorthand, they can contribute to code complexity by obscuring
the origin of imported symbols. Consider:

    use HTTP::Status qw(:constants :is status_message);

The above line imports the C<status_message()> function as well *some other
things* via C<:constants> and C<:is>. What exactly are these things? We'll need
to read the documentation to know for sure.

C<perlimports> can audit your code and expand the line above to list the
symbols which you are actually importing. So, the line above might now look
something like:

    use HTTP::Status qw(
        HTTP_ACCEPTED
        HTTP_BAD_REQUEST
        HTTP_CONTINUE
        HTTP_I_AM_A_TEAPOT
        HTTP_MOVED_PERMANENTLY
        HTTP_NO_CODE
        HTTP_NOT_FOUND
        HTTP_OK
        HTTP_PAYLOAD_TOO_LARGE
        HTTP_PERMANENT_REDIRECT
        HTTP_RANGE_NOT_SATISFIABLE
        HTTP_REQUEST_ENTITY_TOO_LARGE
        HTTP_REQUEST_RANGE_NOT_SATISFIABLE
        HTTP_REQUEST_URI_TOO_LARGE
        HTTP_TOO_EARLY
        HTTP_UNORDERED_COLLECTION
        HTTP_URI_TOO_LONG
        is_cacheable_by_default
        is_client_error
        is_error
        is_info
        is_redirect
        is_server_error
        is_success
        status_message
    );

This is more verbose, but grepping your code will now reveal to you where
something like C<is_cacheable_by_default> gets defined. You have increased the
lines of code, but you have also reduced complexity.

=back

=head1 CAVEATS

There are lots of shenanigans that Perl modules can get up to. This code will
not find exports for all of those cases, but it should only attempt to rewrite
imports which it knows how to handle. Please file a bug report in all other
cases.

=head1 SEE ALSO

L<Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport>,
L<Perl::Critic::Policy::TooMuchCode::ProhibitUnusedInclude> and
L<Perl::Critic::Policy::TooMuchCode::ProhibitUnusedConstant>

=cut
