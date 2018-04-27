#!/usr/bin/perl -ln
# HELP - Filter for xssh --map --[s]diff
#
# DESCRIPTION
#
# Reads stdin (or @ARGV) as produced by xssh --map.
# Not intended for stand-alone usage.
#
# SEE ALSO
# * xssh
# * xssh-map.pl
#
# ENVIRONMENT
# * BASE
# * DIFF
# * IDENT
# * TMPDIR

use warnings;
use strict;
use vars qw($BASE $DEBUG $DIFF $GRP $IDENT $TMPDIR @GRP);
use File::Basename;

sub help() { exec("devops-help $IDENT"); }
sub manpage() { exec("devops-help -v $IDENT"); }

BEGIN {
    $IDENT = exists $ENV{"IDENT"} ? $ENV{"IDENT"} : basename($0);  # XXX: ???
    help() if grep { ($_ eq "-h") or ($_ eq "--help") } @ARGV;
    manpage() if grep { ($_ eq "--manpage") } @ARGV;
    $BASE = exists $ENV{"BASE"} ? $ENV{"BASE"} : "1";
    $DEBUG = exists $ENV{"DEBUG"} ? $ENV{"DEBUG"} : "false";
    $DIFF = exists $ENV{"DIFF"} ? $ENV{"DIFF"} : "diff";
    $TMPDIR = exists $ENV{"TMPDIR"} ? $ENV{"TMPDIR"} : "/tmp";
    warn("$IDENT: info: BASE=$BASE DIFF=$DIFF TMPDIR=$TMPDIR\n")
	if (${DEBUG} =~ /true/);
    $BASE = int($BASE) or
	die(sprintf("%s: error: BASE (%s) out of range\n", $IDENT, $BASE));
}

/^\@(GRP\d+)/ and do {
    close(GRP) if defined $GRP;
    $GRP = "${TMPDIR}/$1";
    push(@GRP, $GRP);
    open(GRP, "> $GRP") or die("${IDENT}: error: cannot open $GRP\n");
    print GRP for split(/[\s,]/, $_);  # expose all hosts in group
    next;
};

print GRP if defined $GRP;

END {
    if (@GRP) {
	print GRP "" if (@GRP > 1);  # normalize w/r/t preceding groups
	close(GRP);
        if (@GRP > 1) {
	    if ($BASE > @GRP) {
		$BASE = @GRP;
		warn(sprintf("%s: warn: only %d groups, --base reset to %d\n",
			     ${IDENT}, scalar(@GRP), $BASE));
	    }
	    my $base = splice(@GRP, ($BASE - 1), 1);
	    for my $file2 (@GRP) {
		system("${DIFF} $base $file2");
	    }
	} else {
	    warn(sprintf("%s: warn: only one group\n", ${IDENT}));
	    system("cat $GRP[0]") if @GRP;
	}
    } else {
	warn(sprintf("%s: warn: no groups?\n", ${IDENT}));
    }
};
