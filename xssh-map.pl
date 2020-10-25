#!/usr/bin/perl -ln
# HELP - Filter for xssh --map
#
# DESCRIPTION
#
# Reads stdin (or @ARGV) as produced by xssh (with no --map in effect).
# Not intended for stand-alone usage.
#
# SEE ALSO
# * xssh
# * xssh-map-diff.pl
#
# KNOWN ISSUES
# * Large results overwhelm the logic?
#   Seen for COMMAND=rpm -ql pnc-ara-python3.

use warnings;
use strict;
use vars qw(%O $IDENT); # lines of output by host

use File::Basename;

sub help() { exec("devops-help $IDENT"); }
sub manpage() { exec("devops-help -v $IDENT"); }

BEGIN {
    $IDENT = basename($0);
    help() if grep { ($_ eq "-h") or ($_ eq "--help") } @ARGV;
    manpage() if grep { ($_ eq "--manpage") } @ARGV;
}

my ($h, $o) = split(/\t/, $_, 2);
push(@{ $O{$h} ||= [] }, $o);

END {
    my %H; # hosts grouped by matching lines of output
    for my $h (sort keys %O) {
        $o = join("\n", @{ $O{$h} ||= [] });  # N.B. Can overflow!
	push(@{ $H{$o} ||= [] }, $h);
    }	
    my $G = "GRP001";
    for $o (sort keys %H) {
        print "\n".q(@).($G++)."\t".join(",",@{ $H{$o} })." #".scalar(@{ $H{$o} });  # host group...
	print $o;		# ...mapped to matching output
    }
}
