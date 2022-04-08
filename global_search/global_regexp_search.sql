CREATE OR REPLACE FUNCTION global_regexp_search(
    search_re text,
    param_tables text[] default '{}',
    param_schemas text[] default '{public}',
    progress text default null -- 'tables','hits','all'
)
RETURNS table(schemaname text, tablename text, columnname text, columnvalue text, rowctid tid)
AS $$
declare
  query text;
begin
  FOR schemaname,tablename IN
      SELECT t.table_schema, t.table_name
      FROM   information_schema.tables t
	JOIN information_schema.table_privileges p ON
	  (t.table_name=p.table_name AND t.table_schema=p.table_schema
	      AND p.privilege_type='SELECT')
	JOIN information_schema.schemata s ON
	  (s.schema_name=t.table_schema)
      WHERE (t.table_name=ANY(param_tables) OR param_tables='{}')
        AND t.table_schema=ANY(param_schemas)
        AND t.table_type='BASE TABLE'
  LOOP
    IF (progress in ('tables','all')) THEN
      raise info '%', format('Searching globally in table: %I.%I',
         schemaname, tablename);
    END IF;

    query := format('SELECT ctid FROM ONLY %I.%I AS t WHERE cast(t.* as text) ~ %L',
	    schemaname,
	    tablename,
	    search_re);
    FOR rowctid IN EXECUTE query
    LOOP
      FOR columnname IN
	  SELECT column_name
	  FROM information_schema.columns
	  WHERE table_name=tablename
	    AND table_schema=schemaname
      LOOP
	query := format('SELECT %I FROM ONLY %I.%I WHERE cast(%I as text) ~ %L AND ctid=%L',
	  columnname, schemaname, tablename, columnname, search_re, rowctid);
        EXECUTE query INTO columnvalue;
	IF columnvalue IS NOT NULL THEN
	  IF (progress in ('hits', 'all')) THEN
	    raise info '%', format('Found in %I.%I.%I at ctid %s, value: ''%s''',
		   schemaname, tablename, columnname, rowctid, columnvalue);
	  END IF;
	  RETURN NEXT;
	END IF;
      END LOOP; -- for columnname
    END LOOP; -- for rowctid
  END LOOP; -- for table
END;
$$ language plpgsql;
