## global_search

```
CREATE FUNCTION global_search(
  search_term text,
  comparator regproc default 'pg_catalog.texteq',   -- comparison function
  tables text[] default null,
  schemas text[] default null,
  progress text default null,   -- 'tables', 'hits', 'all'
  max_width int default -1     -- returned value's max width in chars, or -1 for unlimited
)
RETURNS table(schemaname text, tablename text, columnname text,
              columnvalue text, rowctid tid)
```

`global_search` is a plpgsql function that finds `search_term` in all
columns of all accessible tables. The list of schemas to scan by
default are those accessible through the current `search_path`
(except `pg_catalog` that must be explicitly added if desired).
The `tables` or `schemas` parameters can be
used to scan a specific subset of tables and/or schemas.

The comparison is done with `comparator`, which must be the OID of a
function taking two text arguments and returning a bool with
the result of the match.
It will be called with each column value (cast as `text`) being tested
as its first argument, and `search_term` as its second argument.
Typically, you should just pass the name of the function, and the implicit
casting to `regproc` will take care of translating it into an
OID. Other than `texteq`, built-in functions that may be passed directly
are `textregexeq`, `texticregexeq`, `textlike`, `texticlike`
for regular expressions and the SQL `like` operator (`ic` are the case
insensitive variants). See also the the `\doS+` command in `psql`
for more.

The progress is optionally reported with `raise info` messages, immediately
available to the caller, contrary to the function result that is available
only on function completion.
When `progress` is `tables` or `all`, each table searched into is reported.
When `progress` is `hits` or `all`, each hit is reported.

In all cases, the hits are returned by the function in the form of a
table-like value: `(schemaname text, tablename text, columnname text,
columnvalue text, rowctid tid)`.

Beware that `ctid` are transient, since rows can be relocated
physically. You may use the `REPEATABLE READ` transaction isolation mode to
ensure that the corresponding version of the row is kept around until you're done
with the `ctid`.

The returned column values might be suppressed or truncated by setting
a maximum width with the `max_width` argument.


### Examples:


```
-- Setup
=> CREATE TABLE tst(t text);
=> INSERT INTO tst VALUES('foo'),('bar'),('baz'),('barbaz'),('Foo'),(null);
```

#### Simple equality search:
```
=> SELECT * FROM global_search('Foo');

 schemaname | tablename | columnname | columnvalue | rowctid 
------------+-----------+------------+-------------+---------
 public     | tst       | t          | Foo         | (0,5)
```


#### Regular expression matching
```sql
=> SELECT * FROM global_search('^bar', comparator=>'textregexeq');

 schemaname | tablename | columnname | columnvalue | rowctid 
------------+-----------+------------+-------------+---------
 public     | tst       | t          | bar         | (0,2)
 public     | tst       | t          | barbaz      | (0,4)
(2 rows)
```


#### Case insensitive LIKE (equivalent to: column ILIKE search_term)
```sql
=> SELECT * FROM global_search('fo%', comparator=>'texticlike');

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
SELECT * FROM global_search('fo%', comparator=>'texticlike(text,text)'::regprocedure);
```

#### Find all "incorrect" values with a custom function
The following custom function finds values that do not conform
to the Unicode NFC normalization
Note that even though the second argument is not used in that case,
it needs to be declared nonetheless.

```sql
=> CREATE FUNCTION pg_temp.check_normal_form(text,text)
 returns boolean as
'select $1 is not NFC normalized' -- requires Postgres 13 or newer
language sql;

=> INSERT INTO tst VALUES (E'El Nin\u0303o');
=> SELECT * FROM global_search(null, comparator=>'pg_temp.check_normal_form');

 schemaname | tablename | columnname | columnvalue | rowctid 
------------+-----------+------------+-------------+---------
 public     | tst       | t          | El Niño     | (0,7)
```


#### Find references to the OID of a namespace
That sort of query can be useful when exploring the catalogs.
`2200` is the OID of the `public` namespace.
```sql
=> SELECT * FROM global_search(
     (select oid::text from pg_namespace where nspname='public'), 
     schemas=>'{pg_catalog}'
   );

 schemaname |   tablename    |  columnname  | columnvalue | rowctid 
------------+----------------+--------------+-------------+---------
 pg_catalog | pg_proc        | pronamespace | 2200        | (95,5)
 pg_catalog | pg_description | objoid       | 2200        | (28,58)
 pg_catalog | pg_namespace   | oid          | 2200        | (0,8)
 pg_catalog | pg_depend      | refobjid     | 2200        | (13,70)
 pg_catalog | pg_init_privs  | objoid       | 2200        | (2,27)
(5 rows)
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

=> SELECT * FROM global_search('foo', comparator=>'pg_temp.ci_equal');

 schemaname | tablename | columnname | columnvalue | rowctid 
------------+-----------+------------+-------------+---------
 public     | tst       | t          | foo         | (0,1)
 public     | tst       | t          | Foo         | (0,5)
(2 rows)

```
