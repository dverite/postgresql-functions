/* plperl functions to get and set environment variables */

CREATE FUNCTION getenv(varname text)
RETURNS text
AS $BODY$
 my ($var) = @_;

 $ENV{$var};
$BODY$ language plperl strict stable;

CREATE FUNCTION setenv(varname text, value text)
RETURNS text
AS $BODY$
 my ($var,$value) = @_;

 $ENV{$var}=$value;
$BODY$ language plperl strict stable;
