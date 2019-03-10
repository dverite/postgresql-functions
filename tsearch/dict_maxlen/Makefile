EXTENSION = dict_maxlen
EXTVERSION = 1.0
PG_CONFIG = pg_config

MODULE_big = dict_maxlen
OBJS = dict_maxlen.o

DATA = $(wildcard *.sql)

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
