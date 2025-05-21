#
# Bash functions to use psql as a coprocess
#

# Pass psql arguments
function psql_coproc
{
    coproc PSQL { psql "$@" ; }
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

# Takes a list of queries to run in a transaction
# Retry the entire transaction if a transient error
# occurs
function retriable_transaction
{
  while true
  do
    psql_command "BEGIN;"
    for query in "$@"
    do
      results=$(psql_command "$query")
      # check for errors
      sqlstate=$(psql_command '\echo :SQLSTATE')
      case "$sqlstate" in
	00000)
	  echo "$results"   # output results of $query
	  ;;
	57014 | 40001 | 40P01)
	  # Rollback and retry on
	  # query canceled, or serialization failure, or deadlock
	  # see https://www.postgresql.org/docs/current/errcodes-appendix.html
	  psql_command "ROLLBACK;"
	  continue 2;  # restart transaction at first query
	  ;;
	*)
	  # rollback and stop
	  err=$(psql_command '\echo :LAST_ERROR_MESSAGE');
	  echo 1>&2 "SQL error: $sqlstate $err";
	  psql_command "ROLLBACK;"
	  return
	  ;;
      esac
    done
    psql_command "COMMIT;"
    break;
  done
}
