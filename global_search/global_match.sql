CREATE OR REPLACE FUNCTION global_match(
    search_term text,
    comparator regproc default 'pg_catalog.texteq',   -- comparison function
    tables text[] default null,
    schemas text[] default null,
    progress text default null -- 'tables', 'hits', 'all'
)
RETURNS table(schemaname text, tablename text, columnname text, columnvalue text, rowctid tid)
AS $$
DECLARE
  query text;
  func_schema_name name;
  func_name name;
BEGIN
  SELECT nspname, proname FROM pg_proc p JOIN pg_namespace n ON (n.oid=p.pronamespace)
    WHERE p.oid = comparator
  INTO func_schema_name, func_name;

  IF schemas IS NULL THEN
    -- by default, exclude pg_catalog and non-readable schemas
    schemas := current_schemas(false);
  END IF;

  FOR schemaname,tablename IN
      SELECT t.table_schema, t.table_name
        FROM information_schema.tables t
	JOIN information_schema.schemata s ON
	  (s.schema_name=t.table_schema)
      WHERE (t.table_name=ANY(tables) OR tables is null)
        AND t.table_schema=ANY(schemas)
        AND t.table_type='BASE TABLE'
	AND EXISTS (SELECT 1 FROM information_schema.table_privileges p
	  WHERE p.table_name=t.table_name
	    AND p.table_schema=t.table_schema
	    AND p.privilege_type='SELECT'
	)
  LOOP

    IF (progress in ('tables','all')) THEN
      raise info '%', format('Searching globally in table: %I.%I',
         schemaname, tablename);
    END IF;

    FOR columnname IN
	SELECT column_name
	FROM information_schema.columns
	WHERE table_name=tablename
	  AND table_schema=schemaname
    LOOP
      query := format('SELECT ctid,cast(%I as text) FROM ONLY %I.%I WHERE %I.%I(cast(%I as text), %L)',
	columnname,
	schemaname, tablename,
	func_schema_name, func_name,
	columnname, search_term);

    FOR rowctid,columnvalue IN EXECUTE query
      LOOP
	IF (progress in ('hits', 'all')) THEN
	  raise info '%', format('Found in %I.%I.%I at ctid %s',
		 schemaname, tablename, columnname, rowctid);
	END IF;
	RETURN NEXT;
      END LOOP; -- for rowctid
    END LOOP; -- for columnname
  END LOOP; -- for table
END;
$$ language plpgsql;
