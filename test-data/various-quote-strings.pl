use strict;
use warnings;

# Test various quote-like strings that should not cause errors
use List::Util;

# Simple cases from the issue
my $str1 = "q";
my $str2 = "qq";

# Other quote operators
my $str3 = "qw";
my $str4 = "qx";
my $str5 = "qr";

# Regex operators
my $str6 = "m";
my $str7 = "s";
my $str8 = "tr";
my $str9 = "y";

# Combinations
my $str10 = "q and qq";
my $str11 = pack("qq", 10, 0);

# Words that start with these letters but aren't operators
my $str12 = "quest";
my $str13 = "query";
my $str14 = "queue";

# Real quote operators that should still be processed correctly
my $str15 = q{single quoted string};
my $str16 = qq[double quoted string];
my @str17  = qw(list of words);
my $str18 = qr/regex pattern/;
my $str19 = q(nested (parens) work);
my $str20 = qq|alternative delimiters|;
