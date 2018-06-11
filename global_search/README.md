## global_search

```
FUNCTION global_search(
    search_term text,
    param_tables text[] default '{}',
    param_schemas text[] default '{public}',
    progress text default null -- 'tables','hits','all'
) RETURNS table(schemaname text, tablename text, columnname text, rowctid tid)
```

`global_search` is a plpgsql function that finds `search_term` in all
tables of the public schema, or in a subset of tables delimited by the
`param_tables` or `param_schemas` parameters.

The progress is optionally reported with `raise info` messages, immediately
available to the caller, contrary to the function result that is available
only on function completion.
When `progress` is `tables` or `all`, each table searched into is reported.
When `progress` is `hits` or `all`, each hit is reported.

In all cases, the hits are returned by the function in the form of a
table-like value: `(schemaname text, tablename text, columnname text,
rowctid tid)`.

Example in psql:

	test=> create table tst(t text);
	CREATE TABLE

	test=> insert into tst values('foo'),('bar'),('baz');
	INSERT 0 3

	test=> select * from global_search('bar');
	 schemaname | tablename | columnname | rowctid 
	------------+-----------+------------+---------
	 public     | tst       | t          | (0,2)
	(1 row)

	test=> select * from tst where ctid='(0,2)';
	  t  
	-----
	 bar
	(1 row)

Warning: `ctid` are transient, since rows can be relocated
physically. Use the `REPEATABLE READ` transaction isolation mode to
ensure that the corresponding version of the row is kept around until you're done
with the `ctid`.

## global_regexp_search

```
FUNCTION global_regexp_search(
    search_re text,
    param_tables text[] default '{}',
    param_schemas text[] default '{public}',
    progress text default null -- 'tables','hits','all'
) RETURNS table(schemaname text, tablename text, columnname text, columnvalue text, rowctid tid)
```

This function is like `global_search` except that the search term
is a regular expression against which fields contents are matched with the
`~` operator, and that the values inside columns are part of the returned data.
