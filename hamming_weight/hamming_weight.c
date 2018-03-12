/*
 * Copyright (c) 2015-2018 Daniel VERITE
 * BSD license, see README.md
 */

#include "postgres.h"
#include <string.h>
#include "fmgr.h"

PG_MODULE_MAGIC;

Datum hamming_weight_int4(PG_FUNCTION_ARGS);
Datum hamming_weight_int8(PG_FUNCTION_ARGS);
Datum hamming_weight_bytea(PG_FUNCTION_ARGS);

/* number of bits for all 8-bit numbers */
static const int bitcount[256]={
	0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
	1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
	1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
	1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
	3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
	1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
	3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
	3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
	3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
	4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
};

/* SQL function: hamming_weight(bytea) returns int4 */
PG_FUNCTION_INFO_V1(hamming_weight_bytea);

/* returns the Hamming weight of a bytea value (number of 1's bits) */
Datum
hamming_weight_bytea(PG_FUNCTION_ARGS)
{
	bytea *v = PG_GETARG_BYTEA_PP(0);
	int count=0;
	int len,i;
	unsigned char* buf;

	len = VARSIZE_ANY_EXHDR(v);
	buf = (unsigned char*)VARDATA_ANY(v);
	for (i=0; i<len; i++) {
		count += bitcount[buf[i]&0xff];
	}
	PG_RETURN_INT32(count);
}

/* SQL function: hamming_weight(int4) returns int4 */
PG_FUNCTION_INFO_V1(hamming_weight_int4);

/* returns the Hamming weight of an int4 value (number of 1's bits) */
Datum
hamming_weight_int4(PG_FUNCTION_ARGS)
{
	int32 val = PG_GETARG_INT32(0);
	int count = bitcount[(val>>24)&0xff] + bitcount[(val>>16)&0xff] + 
			bitcount[(val>>8)&0xff] + bitcount[val&0xff];
	PG_RETURN_INT32(count);
}

/* SQL function: hamming_weight(int8) returns int4 */
PG_FUNCTION_INFO_V1(hamming_weight_int8);

/* returns the Hamming weight of an int4 value (number of 1's bits) */
Datum
hamming_weight_int8(PG_FUNCTION_ARGS)
{
	int64 val = PG_GETARG_INT64(0);
	int32 v32 = val & 0xffffffff;
	int count = bitcount[(v32>>24)&0xff] + bitcount[(v32>>16)&0xff] + 
			bitcount[(v32>>8)&0xff] + bitcount[v32&0xff];
	v32 = (val >> 32) & 0xffffffff;
	count += bitcount[(v32>>24)&0xff] + bitcount[(v32>>16)&0xff] + 
			bitcount[(v32>>8)&0xff] + bitcount[v32&0xff];
	PG_RETURN_INT32(count);
}
