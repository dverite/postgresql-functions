CREATE OR REPLACE FUNCTION global_search(
    search_term text,
    param_tables text[] default '{}',
    param_schemas text[] default '{public}',
    progress text default null -- 'tables','hits','all'
)
RETURNS table(schemaname text, tablename text, columnname text, rowctid tid)
AS $$
declare
  query text;
  hit boolean;
begin
  FOR schemaname,tablename IN
      SELECT table_schema, table_name
      FROM information_schema.tables t
      WHERE (t.table_name=ANY(param_tables) OR param_tables='{}')
        AND t.table_schema=ANY(param_schemas)
        AND t.table_type='BASE TABLE'
  LOOP
    IF (progress in ('tables','all')) THEN
      raise info '%', format('Searching globally in table: %I.%I',
         schemaname, tablename);
    END IF;

    query := format('SELECT ctid FROM %I.%I AS t WHERE strpos(cast(t.* as text), %L) > 0',
	    schemaname,
	    tablename,
	    search_term);
    FOR rowctid IN EXECUTE query
    LOOP
      FOR columnname IN
	  SELECT column_name
	  FROM information_schema.columns
	  WHERE table_name=tablename
	    AND table_schema=schemaname
      LOOP
	query := format('SELECT true FROM %I.%I WHERE cast(%I as text)=%L AND ctid=%L',
	  schemaname, tablename, columnname, search_term, rowctid);
        EXECUTE query INTO hit;
	IF hit THEN
	  IF (progress in ('hits', 'all')) THEN
	    raise info '%', format('Found in %I.%I.%I at ctid %s',
		   schemaname, tablename, columnname, rowctid);
	  END IF;
	  RETURN NEXT;
	END IF;
      END LOOP; -- for columnname
    END LOOP; -- for rowctid
  END LOOP; -- for table
END;
$$ language plpgsql;
