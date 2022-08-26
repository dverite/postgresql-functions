# PostgreSQL functions

A repository of custom PostgreSQL functions and extensions.

## diff_tables
A simple plpgsql function that takes two table names (through the
`regclass` type), builds a query comparing their contents, runs
it, and returns a set of diff-like results with the rows that differ.
It does not require a primary key on tables to compare.

## dynamic_pivot
Return a CURSOR pointing to pivoted results of a query passed as the
1st parameter, with sorted headers passed as a query as the 2nd
parameter.  
See https://postgresql.verite.pro/blog/2018/06/19/crosstab-pivot.html for
a lot of context about this function.

## global_search / global_match
Two plpgsql functions that find occurrences of a string or
more generally any kind of text-based matching in all or some of the
tables of an entire database.
It returns the table, column and `ctid` of the rows
containing the value, and the value itself in the case of `global_match`.
The search can be limited to an array of tables and/or of
schemas. Progress is optionally reported by emitting `raise info`
messages.

## hamming_weight
C functions that return the number of bits set to `1` in a bytea, int
or bigint value. The `bytea` variant is available as a built-in function
(named `bit_count`) since PostgreSQL 14.

## large_objects
### lo_size
A plpgsql function that returns the size of a given large object.

### lo_digest
A plperlu function that returns the digest (hash output) of a large
object for any hash supported by perl's Digest module.

## strings/parse_option
A simple function to parse name=value settings.

## strings/plperl/multi_replace
Replace strings by other strings within a larger text, with
Perl s// operator, in a single pass.
Each string in the first array is replaced by the element at the same
index in the second array.

## tsearch/dict_maxlen
A text search dictionary to filter out tokens longer than a given length.

## psql-cli
psqlrc declarations, companion scripts, tricks for the psql command-line interpreter.
