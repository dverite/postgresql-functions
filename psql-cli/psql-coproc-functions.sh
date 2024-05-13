#
# Bash functions to use psql as a coprocess
#

# Pass psql arguments
function psql_coproc
{
    coproc PSQL { psql $1 ; } 
}

function get_uuid
{
    if [ -f /proc/sys/kernel/random/uuid ]; then
	cat /proc/sys/kernel/random/uuid  # linux-specific
    else
	uuidgen
    fi
}

function end_marker
{
    echo "-- END RESULTS MARK -- $(get_uuid) --"
}

function psql_check_alive
{
    if [[ -z "$PSQL_PID" ]]; then exit 1; fi
}

# Send one psql command and get back results
function psql_command
{
    end=$(end_marker)

    psql_check_alive
    echo "$1"  >&${PSQL[1]}
    echo "\\echo '$end'" >&${PSQL[1]}

    psql_check_alive
    while read -r -u ${PSQL[0]} result
    do
	if [[ $result = $end ]]; then
	    break
	fi
	echo $result
    done
}

function psql_quit
{
    echo '\q' >&${PSQL[1]}
}
