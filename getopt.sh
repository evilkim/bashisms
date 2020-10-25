#!/bin/bash
#-----------------------------------------------------------------------------#
# HELP - Provides standardized option parsing and message logging functions
#
# USAGE
#
# [GETOPT_LONG=BOOL,KEY:] [GETOPT_SHORT=BK:] source /PATH/TO/getopt.sh
#
# DESCRIPTION
#
# Invokes getopt(1) to parse OPTIONS from $@ for a calling Bash script
# with usage like `COMMAND [OPTIONS] [ARGS]`, leaving just ARGS in $@.
#
# There is tight coupling with the functions in logging.sh which are
# used here and thus also provided to the caller.
#
# The standard options (see OPTIONS) align to true/false values of
# matching variables (see OUTPUTS). These are primarily used by the
# message logging functions, but the caller is free to exploit
# further.
#
# Support is also provided for user-defined GETOPT_SHORT and
# GETOPT_LONG options (see INPUTS). When present in $@, these are
# stripped of the leading dash(es) and returned in the associative
# array GETOPT (see OUTPUTS). A switch (option with no required value)
# is set to true when present. The absence of an option returned in
# GETOPT is left for the user to define (see EXAMPLE).
#
# For scripts requiring more sophisticated and non-trivial option
# handling, use this file as a template:
#
#	Starting at the #---CUT-HERE---# divider below, copy/paste
#	into a Bash script and modify sparingly to add custom options.
#	E.g. support for a --no-long option that is meant to disable a
#	prior --long option, or other tricky interactions between
#	options.
#
#	You may expand upon the meaning of, but do not otherwise
#	override the default options which are used by logging.sh.
#
# INPUTS
#
# * GETOPT_LONG		Comma separated long options (getopt --long).
# * GETOPT_SHORT	Single character options (getopt -o).
# * LONGOPTS		Deprecated, use GETOPT_LONG instead.
# * SHORTOPTS		Deprecated, use GETOPT_SHORT instead.
#
# OUTPUTS
#
# * DEBUG		false unless -d|--debug (log_debug)
# * QUIET		false unless -q|--quiet (log_info)
# * VERBOSE		false unless -v|--verbose (log_verbose)
# * WARNINGS		true unless -W|--no-warnings (log_warning)
# * XTRACE		":" (no-op) unless -d|--debug or -v|--verbose when
#			defined as "set -o xtrace". See template.sh.
# * GETOPT
#	For each standard option present in $@, the short equivalent
#	is appended to GETOPT[OPTIONS]. These are preceded by a
#	leading dash. This is a convenience for the caller to pass
#	along to related scripts for consistent behavior.
#	
#	In addition, any user-defined options present are returned
#	here.
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
#
# EXAMPLE
#
# GETOPT_LONG=bool,key: GETOPT_SHORT=bk: source getopt.sh || exit
# BOOL=${GETOPT[bool]:-${GETOPT[b]:-false}}  # Either --bool or -b yields true
# KEY=${GETOPT[key]:-${GETOPT[k]:-default}}  # --key VALUE overrides -k VALUE
#
# SEE ALSO
# * logging.sh		Required. Must be co-located with getopt.sh.
# * template.sh		Copy/paste to create a new Bash script.
#
# ACKNOWLEDGMENT
# * https://gist.github.com/cosimo/3760587
#
# TODO
# * Support increase verbosity with -v / decrease with -q.
# * Warn if any standard options in GETOPT_SHORT, GETOPT_LONG.
# * Support aliases setting same target (x|xxx => -x, --xxx => GETOPT[xxx]).

#-----------------------------------------------------------------------------#
# INIT

# Caller should have set IDENT and USAGE (set here for getopt.sh --help)
: ${IDENT:=${0##*/}}
: ${USAGE:=source ${BASH_SOURCE[0]%/*}/$IDENT}
source ${BASH_SOURCE[0]%/*}/logging.sh || exit

: ${GETOPT_SHORT:=${SHORTOPTS:-}}  # deprecated - alternate config
: ${GETOPT_LONG:=${LONGOPTS:-}}	   # deprecated - alternate config

#-----------------------------------------------------------------------------#
# FUNCTIONS

:

#---CUT-HERE---#
#-----------------------------------------------------------------------------#
# OPTIONS

GETOPT_SHORT=hdqvW${GETOPT_SHORT}		# User-defined -o options

GETOPT_LONG=${GETOPT_LONG:+,}${GETOPT_LONG}	# User-defined --long options
GETOPT_LONG=help,manpage,debug,quiet,verbose,no-warnings${GETOPT_LONG}

# Defaults:
DEBUG=false
QUIET=false
VERBOSE=false
WARNINGS=true

getopt --test >/dev/null && { log_error "incompatible getopt(1)"; exit 1; }

# With POSIXLY_CORRECT in the environment, parsing stops at 1st non-option
GETOPT=$(env POSIXLY_CORRECT=\
	     getopt -o "$GETOPT_SHORT" --long "$GETOPT_LONG" -- "$@")
if [[ $? != 0 ]]; then log_usage "Try '$IDENT --manpage' for valid OPTIONS."; fi
eval set -- $GETOPT

declare -A GETOPT    # Associative array of user-defined option values

while [[ "$1" == -* ]]; do
    case "$1" in
	#---Standard Options---#
	-h|--help|--manpage) log_help "$1";;
	-d|--debug) DEBUG=true;;
	-q|--quiet) QUIET=true;;
	-v|--verbose) VERBOSE=true;;
	-W|--no-warnings) WARNINGS=false;;
	--) shift; break;;	# canonical end of options
	#---User Defined Options---#
	--*)
	    GETOPT[OPTIND]=${1/--/}
	    if echo ",$GETOPT_LONG," | grep -q -e ",${GETOPT[OPTIND]}:,"; then
		# TODO: Warn if overwriting with new value, or append as CSV?
		GETOPT[${GETOPT[OPTIND]}]="$2"; shift
	    else
		GETOPT[${GETOPT[OPTIND]}]=true
	    fi
	    log_debug "GETOPT[${GETOPT[OPTIND]}]=${GETOPT[${GETOPT[OPTIND]}]}"
	    ;;
	-*)
	    GETOPT[OPTIND]=${1/-/}
	    if echo "$GETOPT_SHORT" | grep -q -e "${GETOPT[OPTIND]}:"; then
		# TODO: Warn if overwriting with new value, or append as CSV?
		GETOPT[${GETOPT[OPTIND]}]="$2"; shift
	    else
		GETOPT[${GETOPT[OPTIND]}]=true
	    fi
	    log_debug "GETOPT[${GETOPT[OPTIND]}]=${GETOPT[${GETOPT[OPTIND]}]}"
	    ;;
    esac
    shift
done

unset GETOPT[OPTIND]		# *Reserved for internal use only*

# Pass standard OPTIONS back to caller for forwarding to related scripts:
GETOPT[OPTIONS]=""
$DEBUG && GETOPT[OPTIONS]=${GETOPT[OPTIONS]}d
$QUIET && GETOPT[OPTIONS]=${GETOPT[OPTIONS]}q
$VERBOSE && GETOPT[OPTIONS]=${GETOPT[OPTIONS]}v
$WARNINGS || GETOPT[OPTIONS]=${GETOPT[OPTIONS]}W
if [[ -n "${GETOPT[OPTIONS]}" ]]; then GETOPT[OPTIONS]=-${GETOPT[OPTIONS]}; fi

# Set XTRACE for caller to defined xtrace function (see default below).
if $DEBUG || $VERBOSE; then
    XTRACE="set -o xtrace"
else
    XTRACE="set +o xtrace"
fi

# define xtrace() to run given command as follows:
if $DEBUG; then			# -xx|--xtrace --xtrace
    function xtrace {
	# Display call stack and enable xtrace
	local callers=(${FUNCNAME[@]})
	callers[0]+=":"
	echo >&2 "${IDENT}: ${callers[*]}"
	($XTRACE; "$@")
    }
elif $VERBOSE; then		# -x|--xtrace
    # Enable xtrace
    function xtrace { ($XTRACE; "$@"); }
else				# -X|--no-xtrace
    # Disable xtrace
    function xtrace { ("$@"); }	 # Runs in subshell for consistency.
fi
