# PostgreSQL functions

A repository of custom PostgreSQL functions and extensions.

## diff_tables
A simple plpgsql function that takes two table names (through the
`regclass` type), builds a query comparing their contents, runs
it, and returns a set of diff-like results with the rows that differ.
It does not require a primary key on tables to compare.

## global_search / global_regexp_search
Two plpgsql functions that find occurrences of a string or
a regular expression in all or some of the tables of an entire
database.  It returns the table, column and `ctid` of the rows
containing the value, and the value itself in the case of a regexp
search.
The search can be limited to an array of tables and/or of
schemas. Progress is optionally reported by emitting `raise info`
messages.

## hamming_weight
C functions that return the number of bits set to `1` in a bytea, int
or bigint value.

## large_objects
### lo_size
A plpgsql function that returns the size of a given large object.

### lo_digest
A plperlu function that returns the digest (hash output) of a large
object for any hash supported by perl's Digest module.
