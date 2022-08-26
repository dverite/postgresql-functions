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

## global_match

```
FUNCTION global_match(
    search_term text,
    comparator regproc default 'texteq',   -- comparison function
    tables text[] default '{}',
    schemas text[] default '{public}',
    progress text default null -- 'tables','hits','all'
) RETURNS table(schemaname text, tablename text, columnname text, columnvalue text, rowctid tid)
```

This function is a generalized version of `global_search` that takes the OID
of a comparison function as the argument, rather than just testing for equality.
The result set also include the column values that match (`columnvalue`).
All columns of all tables matching the `tables` and `schemas` parameters are scanned.

The comparison function must accept two `text` arguments and return a
`boolean` value (`true` when there's a match).
This function is called with each value (cast as `text`) being tested
as its first argument, and `search_term` as its second argument.

Many built-in comparisons functions can be used directly by refering to them
by name (see the examples below, and the `\doS+` command in `psql`)


### Examples:


```
-- Setup
=> CREATE TABLE tst(t text);
=> INSERT INTO tst VALUES('foo'),('bar'),('baz'),('barbaz'),('Foo'),(null);
```


#### Regular expression matching
```sql
=> SELECT * FROM global_match('^bar', comparator=>'textregexeq');

 schemaname | tablename | columnname | columnvalue | rowctid 
------------+-----------+------------+-------------+---------
 public     | tst       | t          | bar         | (0,2)
 public     | tst       | t          | barbaz      | (0,4)
(2 rows)
```


#### Exact matching
`global_search('foo')` would likely be faster, but that's just to
show that the equality match is the default comparator.
```sql
=> SELECT * FROM global_match('foo');

 schemaname | tablename | columnname | columnvalue | rowctid 
------------+-----------+------------+-------------+---------
 public     | tst       | t          | foo         | (0,1)
(1 row)
```

#### Case insensitive LIKE (equivalent to: column ILIKE search_term)
```sql
=> SELECT * FROM global_match('fo%', comparator=>'texticlike');

 schemaname | tablename | columnname | columnvalue | rowctid 
------------+-----------+------------+-------------+---------
 public     | tst       | t          | foo         | (0,1)
 public     | tst       | t          | Foo         | (0,5)
(2 rows)
```

Sometimes there are several functions with the same name. In the
case of `texticlike`, the `citext` extension overloads this function
with two variants that take a `citext` parameter instead of `text`.
In that kind of case, you want to use the `regprocedure` cast with a
function name qualified with arguments to disambiguate.

For instance:

```sql
SELECT * FROM global_match('fo%', comparator=>'texticlike(text,text)'::regprocedure);
```

#### Find all "incorrect" values with a custom function
This custom function finds values that are either NULL or do not conform
to the Unicode NFC normalization
Note that even though the second argument is not used in that case,
it needs to be declared nonetheless.

```sql
=> CREATE FUNCTION pg_temp.check_correctness(text,text)
 returns boolean as
'select $1 is null or $1 is not NFC normalized' -- requires Postgres 13 or newer
language sql;

=> SELECT * FROM global_match(null, comparator=>'pg_temp.check_correctness);

 schemaname | tablename | columnname | columnvalue | rowctid 
------------+-----------+------------+-------------+---------
 public     | tst       | t          |             | (0,6)
(1 row)
```


#### Find references to the OID of a namespace
That sort of query can be useful when exploring the catalogs.
`2200` is the OID of the `public` namespace.
```sql
=> SELECT * FROM global_match(
     (select oid::text from pg_namespace where nspname='public'), 
     schemas=>'{pg_catalog}'
   );

 schemaname |   tablename    |  columnname  | columnvalue | rowctid 
------------+----------------+--------------+-------------+---------
 pg_catalog | pg_type        | typnamespace | 2200        | (14,14)
 pg_catalog | pg_type        | typnamespace | 2200        | (14,15)
 pg_catalog | pg_proc        | pronamespace | 2200        | (96,1)
 pg_catalog | pg_class       | relnamespace | 2200        | (0,13)
 pg_catalog | pg_description | objoid       | 2200        | (28,79)
 pg_catalog | pg_namespace   | oid          | 2200        | (0,5)
 pg_catalog | pg_depend      | refobjid     | 2200        | (13,74)
 pg_catalog | pg_depend      | refobjid     | 2200        | (13,84)
 pg_catalog | pg_init_privs  | objoid       | 2200        | (2,26)
(9 rows)
```

#### Case and accent insensitive global search

Using an ICU collation for advanced non-bitwise equality tests.

```
-- create a collation that ignores accents and case
=> CREATE COLLATION nd (
  provider = 'icu',
  locale = '@colStrength=primary',
  deterministic = false
);

=> CREATE FUNCTION pg_temp.ci_equal(text,text)
 returns boolean as
'select $1=$2 collate "nd"'
language sql;

=> SELECT * FROM global_match('foo', comparator=>'pg_temp.ci_equal');

 schemaname | tablename | columnname | columnvalue | rowctid 
------------+-----------+------------+-------------+---------
 public     | tst       | t          | foo         | (0,1)
 public     | tst       | t          | Foo         | (0,5)
(2 rows)

```
