/*
 * Parse a GUC as the C function ParseLongOption() from Postgres source
 * code in src/backend/utils/misc/guc.c
 * Input: string of the form 'name=value'
 * Output: name and value as a record.
 */
CREATE OR REPLACE FUNCTION
 parse_option(string text, name OUT text,  value OUT text)
RETURNS record
as $$
declare
 p int := strpos(string, '=');
begin
  if (p > 0) then
    name := replace(left(string, p-1), '-', '_');
    value := substr(string, p+1);
  else
    name := replace(string, '-', '_');
    value := NULL;
  end if;
end
$$ language plpgsql immutable;

/*
 * Consider this less readable version if you want it in the
 *  SQL language (it doesn't seem to be faster in that case).
 */
/*
CREATE OR REPLACE FUNCTION
 parse_option(string text, name OUT text,  value OUT text)
RETURNS record
as $$
 select
    replace(left(string, greatest(strpos($1, '=')-1, 0)), '-', '_'),
      substr(string, strpos($1, '=')+1);
$$ language sql immutable;
*/
