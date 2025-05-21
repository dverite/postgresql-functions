#!/bin/bash

# Takes a tar file in standard input containing 'tablename.copy' files
# in COPY text format.
# Each file is \copy'ed with psql into 'tablename'
# The import is done in a single transaction and without
# extracting any file to disk

set -e

source psql-coproc-functions.sh

psql_coproc -AtX -v ON_ERROR_STOP=1 --single-transaction

fifo_names="$(mktemp -u)-$(get_uuid)"
mkfifo -m 0600 $fifo_names

fifo_contents="$(mktemp -u)-$(get_uuid)"
mkfifo -m 0600 $fifo_contents

function cleanup
{
    rm -f $fifo_names $fifo_contents
}

trap cleanup EXIT

end_files=$(end_marker)

cat | (
  tar --to-command "echo \$TAR_FILENAME >>$fifo_names; cat > $fifo_contents" \
     -xjf - ;
  echo "$end_files" >$fifo_names
) &


while read -r copyfilename < $fifo_names; do
  if [[ "$copyfilename" = "$end_files" ]]; then
    break
  else
    tablename=${copyfilename%.copy}
    echo "Importing $copyfilename into $tablename"
    psql_command "\\copy $tablename from $fifo_contents"
  fi
done

psql_check_alive
echo '\q' >&${PSQL[1]}

# Wait for completion of background processes
wait
