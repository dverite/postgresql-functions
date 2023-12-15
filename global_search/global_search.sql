CREATE or replace FUNCTION global_search(
  search_term text,
  comparator regproc default 'pg_catalog.texteq',   -- comparison function
  tables text[] default null,
  schemas text[] default null,
  progress text default null,   -- 'tables', 'hits', 'all'
  max_width int default -1     -- returned value's max width in chars, or -1 for unlimited
)
RETURNS table(schemaname text, tablename text, columnname text, columnvalue text, rowctid tid)
AS $$
DECLARE
  query text;
  clauses text[];
  columns text[];
  pos int;
  positions int[];
  col_expr text;
BEGIN
  IF schemas IS NULL THEN
    -- by default, exclude pg_catalog and non-readable schemas
    schemas := current_schemas(false);
  END IF;

  FOR schemaname,tablename IN
    -- select tables for which all columns are readable
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
      RAISE INFO '%', format('Searching globally in table: %I.%I',
         schemaname, tablename);
    END IF;

    -- Get lists of columns and per-column boolean expressions
    SELECT array_agg(column_name ORDER BY ordinal_position),
           array_agg(format('%s(cast(%I as text), %L)', comparator, column_name, search_term)
	     ORDER BY ordinal_position)
      FROM information_schema.columns
      WHERE table_name=tablename
        AND table_schema=schemaname
    INTO columns, clauses;

    -- Main query to get each matching row and the ordinal positions of matching columns
    query := format('SELECT s.ctid, p from (SELECT ctid,'
		    'array_positions(array[%s],true) AS p FROM ONLY %I.%I) s'
		    ' WHERE cardinality(p)>0',
      array_to_string(clauses, ','), schemaname, tablename );

    FOR rowctid,positions IN EXECUTE query -- for each matching row
    LOOP
      FOREACH pos IN ARRAY positions -- for each matching field
      LOOP
	columnname := columns[pos];
	IF (max_width <> 0) THEN -- fetch value only if needed
	  IF (max_width > 0) THEN
	    -- fetch a truncated value
	    col_expr := format('left(%I,%s)', columnname, max_width);
	  ELSE
	    col_expr := format('%I', columnname);
	  END IF;
	  EXECUTE format('SELECT %s FROM %I.%I WHERE ctid=''%s''',
	    col_expr, schemaname, tablename, rowctid) INTO columnvalue;
	ELSE
	  columnvalue:=null;
	END IF;
	IF (progress in ('hits', 'all')) THEN
	  RAISE INFO '%', format('Found in %I.%I.%I at ctid %s',
	     schemaname, tablename, columnname, rowctid);
	END IF;
	RETURN NEXT;
      END LOOP;
    END LOOP;
  END LOOP; -- for each table
END;
$$ language plpgsql;
