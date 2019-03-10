#include "postgres.h"

#include "commands/defrem.h"
#include "tsearch/ts_utils.h"
#include "mb/pg_wchar.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(dictmaxlen_init);
PG_FUNCTION_INFO_V1(dictmaxlen_lexize);

Datum dictmaxlen_lexize(PG_FUNCTION_ARGS);
Datum dictmaxlen_init(PG_FUNCTION_ARGS);

typedef struct
{
	int			maxlen;
} DictMaxLen;

Datum
dictmaxlen_init(PG_FUNCTION_ARGS)
{
	List	   *options = (List *) PG_GETARG_POINTER(0);
	DictMaxLen   *d;
	ListCell   *l;

	d = (DictMaxLen *) palloc0(sizeof(DictMaxLen));

	d->maxlen = 50;				/* default */

	foreach(l, options)
	{
		DefElem    *defel = (DefElem *) lfirst(l);

		if (strcmp(defel->defname, "length") == 0)
		{
			d->maxlen = atoi(defGetString(defel));
		}
		else
		{
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("unrecognized dictionary parameter: \"%s\"",
							defel->defname)));
		}
	}

	PG_RETURN_POINTER(d);
}

Datum
dictmaxlen_lexize(PG_FUNCTION_ARGS)
{
	DictMaxLen	*d = (DictMaxLen *) PG_GETARG_POINTER(0);
	char	   	*token = (char *) PG_GETARG_POINTER(1);
	int			byte_length = PG_GETARG_INT32(2);

	if (pg_mbstrlen_with_len(token, byte_length) > d->maxlen)
	{
		/* If the word is longer than our max length, return an empty
		 * lexeme */
		TSLexeme   *res = palloc0(sizeof(TSLexeme));
		/* res[0].lexeme = NULL; */       /* implied by palloc0() */
		PG_RETURN_POINTER(res);
	}
	else
	{
		/* If the word is short, pass it unmodified */
		PG_RETURN_POINTER(NULL);
	}
}
