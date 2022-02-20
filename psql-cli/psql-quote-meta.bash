#!/bin/bash

# This function returns its arguments quoted to be safely injected
# into a psql meta-command.
# Note: it does not transform control characters (CR,FF,tab...)
function quote_psql_meta
{
   local t=${1//\\/\\\\}
   t=${t//\'/\\\'}
   echo "'$t'"
}

