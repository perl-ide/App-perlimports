use strict;
use warnings;

# Borrowed from Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers

use Perl::Critic::Utils qw( $BACKTICK $PERIOD );

my $UNSIGNED_NUMBER = qr{
            \d+ (?: [$PERIOD] \d+ )?  # 1, 1.5, etc.
        |   [$PERIOD] \d+             # .3, .7, etc.
      }xms;

my $rule = '12345';

if ( $rule =~ m/$BACKTICK/xms ) {
    print 'ok';
}
