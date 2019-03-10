
-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION dictmaxlen" to load this file. \quit

CREATE FUNCTION dictmaxlen_init(internal)
        RETURNS internal
        AS 'MODULE_PATHNAME'
        LANGUAGE C STRICT;

CREATE FUNCTION dictmaxlen_lexize(internal, internal, internal, internal)
        RETURNS internal
        AS 'MODULE_PATHNAME'
        LANGUAGE C STRICT;

CREATE TEXT SEARCH TEMPLATE dictmaxlen_template (
        LEXIZE = dictmaxlen_lexize,
	INIT   = dictmaxlen_init
);

/*
Instantiate with:

CREATE TEXT SEARCH DICTIONARY dictmaxlen (
	TEMPLATE = dictmaxlen_template,
	LENGTH = ?
);

COMMENT ON TEXT SEARCH DICTIONARY dictmaxlen IS
  'A dictionary to filter out long tokens';
*/
