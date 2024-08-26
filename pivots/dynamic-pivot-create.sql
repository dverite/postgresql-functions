/*
 Create a table or view for the pivoted results of a query
 passed as the 1st parameter, with sorted headers passed as a query
 as the 2nd parameter.
 3rd parameter: name of the table or view
 4th parameter: object type:
   'v': view, 'tv': temp view, 't': table, 'tt': temp table, 'm': materialized view

 See https://postgresql.verite.pro/blog/2018/06/19/crosstab-pivot.html
 for a lot of context about this function.

 Example usage:
    CREATE TABLE tmp1 (row_id, key, val) AS
    VALUES
    (1, 'a', 1),
    (1, 'b', 2),
    (2, 'a', 3),
    (2, 'b', 4);

    SELECT dynamic_pivot_create(
    'select row_id, key, val from tmp1',
    'select distinct key from tmp1',
    'm_tmp1', 'mv');

    SELECT * FROM m_tmp1;
*/
CREATE OR REPLACE FUNCTION dynamic_pivot_create(central_query text,
                                                headers_query text,
                                                obj_name text,
                                                obj_type text default 'tv')
RETURNS void AS
$$
DECLARE
  left_column text;
  header_column text;
  value_column text;
  h_value text;
  headers_clause text;
  query text;
  j json;
  r record;
  i int:=1;
BEGIN
  -- find the column names of the source query
  EXECUTE 'select row_to_json(_r.*) from (' ||  central_query || ') AS _r' into j;
  FOR r in SELECT * FROM json_each_text(j)
  LOOP
    IF (i=1) THEN left_column := r.key;
      ELSEIF (i=2) THEN header_column := r.key;
      ELSEIF (i=3) THEN value_column := r.key;
    END IF;
    i := i+1;
  END LOOP;

  -- build the dynamic transposition query, based on the canonical model
  -- (CASE WHEN...)
  FOR h_value in EXECUTE headers_query
  LOOP
    headers_clause := concat(headers_clause,
     format(chr(10)||',min(case when %I=%L then %I::text end) as %I',
           header_column,
	   h_value,
	   value_column,
	   h_value ));
  END LOOP;

  query := format('CREATE %s %I AS SELECT %I %s FROM (select *,row_number() over() as rn from (%s) AS _c) as _d GROUP BY %I order by min(rn)',
           case obj_type
	     when 't'  then 'TABLE'
	     when 'tt' then 'TEMP TABLE'
	     when 'v'  then 'VIEW'
	     when 'tv' then 'TEMP VIEW'
	     when 'mv' then 'MATERIALIZED VIEW'
	     else 'VIEW'
           end,
           obj_name,
           left_column,
	   headers_clause,
	   central_query,
	   left_column);

 -- RAISE NOTICE '%', query;
 EXECUTE query;

END
$$ LANGUAGE plpgsql;
