# PostgreSQL functions

A repository of custom PostgreSQL functions and extensions.

## global_search
A plpgsql function that finds occurrences of a string in all
or some of the tables of an entire database.  
It returns the table, column and `ctid` of the rows containing
the value.  
The search can be limited to an array of tables and/or of
schemas. Progress is optionally reported by emitting `raise info` messages.

## hamming_weight
C functions that return the number of bits set to `1` in a bytea, int or bigint value.

## large_objects
### lo_size
A plpgsql function that returns the size of a given large object.

### lo_digest
A plperlu function that returns the digest (hash output) of a large
object for any hash supported by perl's Digest module.
