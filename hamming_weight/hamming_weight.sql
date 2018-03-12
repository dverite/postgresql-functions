/*
  Compute the Hamming weight (count of bits set to '1')
  for bytea, int4, int8
*/
CREATE FUNCTION hamming_weight(bytea) RETURNS int
 AS '$libdir/hamming_weight.so', 'hamming_weight_bytea'
LANGUAGE C immutable strict;

CREATE FUNCTION hamming_weight(int) RETURNS int
 AS '$libdir/hamming_weight.so', 'hamming_weight_int4'
LANGUAGE C immutable strict;

CREATE FUNCTION hamming_weight(bigint) RETURNS int
 AS '$libdir/hamming_weight.so', 'hamming_weight_int8'
LANGUAGE C immutable strict;
