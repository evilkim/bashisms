#!/bin/bash
#-----------------------------------------------------------------------------#
# HELP - Copy/paste this template into a new Bash script for consistent UX
#
USAGE="${IDENT:=${0##*/}} [OPTIONS] [ARGS]"
#
# DESCRIPTION
#
# (TBD)
#
# OPTIONS
#
# -h|--help	Print HELP and USAGE lines, suggest --manpage, and exit.
#
# --manpage	Print this message and exit.
#
# -d|--debug	Enable diagnostic messages.
#
# -q|--quiet	Disable informational messages.
#
# -v|--verbose	Enable extra informational messages.
#
# -W|--no-warnings
#		Suppress warning messages.
#
# --		Required if the first non-OPTION starts with a '-'.

#-----------------------------------------------------------------------------#
# INIT

# See https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail
set -euo pipefail

BINDIR=$(cd $(dirname "$0") && pwd)
# As needed: LIBDIR=$(cd "${BINDIR}/../lib" && pwd)

#-----------------------------------------------------------------------------#
# OPTIONS

PATH="${BINDIR}:${PATH}"\
    GETOPT_SHORT=bk:\
    GETOPT_LONG=bool,key:\
    source getopt.sh || exit

# EXAMPLES
BOOL=${GETOPT[bool]:-${GETOPT[b]:-false}}  # Either --bool or -b yields true
KEY=${GETOPT[key]:-${GETOPT[k]:-""}}       # --key VALUE overrides -k VALUE

#-----------------------------------------------------------------------------#
# FUNCTIONS

:

#-----------------------------------------------------------------------------#
# main()

# EXAMPLES
$DEBUG && set | grep -e GETOPT -e log_
$BOOL || log_warning "BOOL is not set"
log_info "BOOL=$BOOL KEY=$KEY"
$VERBOSE && for arg in $*; do log_info "arg=$arg"; echo "arg=$arg"; done
