# Makefile for hamming_weight
# Assumes that pg_config is installed
# See https://www.postgresql.org/docs/current/static/app-pgconfig.html
# and https://www.postgresql.org/docs/current/static/extend-pgxs.html
# on how to extend PostgreSQL with custom functions in general

ifndef PG_CONFIG
PG_CONFIG = pg_config
endif

INCLUDEDIRS := -I.
INCLUDEDIRS += -I$(shell $(PG_CONFIG) --includedir-server)
INCLUDEDIRS += -I$(shell $(PG_CONFIG) --includedir)
CFLAGS := $(shell $(PG_CONFIG) --cflags)
CFLAGS_SL := $(shell $(PG_CONFIG) --cflags_sl)

# If you are using shared libraries, make sure this location can be
# found at runtime (see /etc/ld.so.conf and ldconfig command).
LIBDIR = -L$(shell $(PG_CONFIG) --libdir)
# This is where the shared object should be installed
LIBINSTALL = $(shell $(PG_CONFIG) --pkglibdir)

all: hamming_weight.so

hamming_weight.so: hamming_weight.c Makefile
	gcc $(CFLAGS) $(CFLAGS_SL)  $(INCLUDEDIRS) -o hamming_weight.o -c hamming_weight.c
	gcc -shared -o hamming_weight.so hamming_weight.o $(LIBDIR) -lpq -lm

install: hamming_weight.so
	cp $? $(LIBINSTALL)
