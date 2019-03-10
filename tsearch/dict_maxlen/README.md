## dict_maxlen

A dictionary (for PostgreSQL [text search engine](https://www.postgresql.org/docs/current/textsearch.html)) that filters out tokens longer than a given length.

### Example of use:

Consider this query for a baseline comparison, using the english built-in
configuration:

```
=# select to_tsvector('english', 'This is a long checksum that will be indexed: 81c3b1eccdb8e1ca7a5475aaf2f362ab3ec2ac4274974a12626d4bf603db4d6f');
                                              to_tsvector
-------------------------------------------------------------------------------------------------------
 '81c3b1eccdb8e1ca7a5475aaf2f362ab3ec2ac4274974a12626d4bf603db4d6f':10 'checksum':5 'index':9 'long':4
```

Installation of the dictionary, in a new distinct text search configuration:

```
CREATE EXTENSION dict_maxlen;

CREATE TEXT SEARCH DICTIONARY dictmaxlen (
  TEMPLATE = dictmaxlen_template,
  LENGTH = 40 -- or another maximum number of characters
);
COMMENT ON TEXT SEARCH DICTIONARY dictmaxlen IS 'A dictionary to filter out long lexemes';

CREATE TEXT SEARCH CONFIGURATION mytsconf ( COPY = pg_catalog.english );

-- Map the dictionary to some of the token types produced by the parser

ALTER TEXT SEARCH CONFIGURATION mytsconf
 ALTER MAPPING FOR asciiword, word
  WITH dictmaxlen,english_stem;

ALTER TEXT SEARCH CONFIGURATION mytsconf
 ALTER MAPPING FOR numword
  WITH dictmaxlen,simple;

```

Result with the dictionary installed and configured to filter out tokens longer than 40 characters:

```

=# select to_tsvector('mytsconf', 'This is a long checksum that will NOT be indexed: 81c3b1eccdb8e1ca7a5475aaf2f362ab3ec2ac4274974a12626d4bf603db4d6f');
           to_tsvector
---------------------------------
 'checksum':5 'index':10 'long':4


```
