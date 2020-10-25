#!/bin/bash
#-----------------------------------------------------------------------------#
# HELP - Provides Bash functions akin to Python logging

function log_fatal {
    local rc="$1"; shift
    echo >&2 "$IDENT: fatal: status=$rc: $*"
    exit $rc
}
function log_error { echo >&2 "$IDENT: error: $*"; }
function log_warning { $WARNINGS && echo >&2 "$IDENT: warning: $*"; true; }
function log_info { $QUIET || echo >&2 "$IDENT: info: $*"; }
function log_verbose { $VERBOSE && log_info "$*"; true; }
function log_debug { $DEBUG && echo >&2 "$IDENT: debug: $*"; true; }

function log_stderr {
    # Prefix all captured stderr with "{{ident}}: ", back to stderr
    # Usage: {{command}} 2> >(log_stderr [IDENT])
    local ident="${*:-${IDENT}: stderr}"
    perl >&2 -lpe 's/^/${ident}: /' -s -- -ident="${ident}"
}

function log_stdout {
    # Prefix all captured stdout with "{{ident}}: ", back to stdout
    # Usage: {{command}} 1> >(log_stdout [IDENT])
    local ident="${*:-${IDENT}: stdout}"
    perl -lpe 's/^/${ident}: /' -s -- -ident="${ident}"
}

function log_usage {
    if [[ -n "$1" ]]; then local rc=2; log_error "$*"; else rc=0; fi
    echo >&2 "Usage: $USAGE"
    exit $rc;
}

function log_help {
    case "$1" in
	--manpage)
	    IDENT="$IDENT" perl -lne '
(s/^# HELP - /# NAME\n\n# $ENV{IDENT} - /../^$/) and do {
    s/^USAGE="(source\s+)?(\S+)(\s+.+)"/SYNOPSIS\n\n${1}$ENV{IDENT}${3}/;
    s/\$\{IDENT\}/$ENV{IDENT}/g;
    s/^(\S+)=/# \tDefault: /;
    print;
    exit if /^$/;
};
' $0 |
		expand |
		perl -lpe 's/^# ?//' |
		less -F
	    ;;
	-h|--help|*)		# Default to brief usage statement
	    perl -lne 's/^\# HELP - // and print,exit;' $0
	    echo "Usage: $USAGE"
	    echo "Try '$IDENT --manpage' for more information."	 # a la wc(1)
	    ;;
    esac
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    IDENT=${0##*/}
    USAGE="source $0"
    log_usage "Calling this script directly is not generally useful"
fi
