# Makefile for hamming_weight
# Assumes that pg_config is installed
# See https://www.postgresql.org/docs/current/static/app-pgconfig.html
# and https://www.postgresql.org/docs/current/static/extend-pgxs.html
# on how to extend PostgreSQL with custom functions in general

INCLUDEDIRS := -I.
INCLUDEDIRS += -I$(shell pg_config --includedir-server)
INCLUDEDIRS += -I$(shell pg_config --includedir)
CFLAGS := $(shell pg_config --cflags)
CFLAGS_SL := $(shell pg_config --cflags_sl)

# If you are using shared libraries, make sure this location can be
# found at runtime (see /etc/ld.so.conf and ldconfig command).
LIBDIR = -L$(shell pg_config --libdir)
# This is where the shared object should be installed
LIBINSTALL = $(shell pg_config --pkglibdir)

all: hamming_weight.so

hamming_weight.so: hamming_weight.c Makefile
	gcc $(CFLAGS) $(CFLAGS_SL)  $(INCLUDEDIRS) -o hamming_weight.o -c hamming_weight.c
	gcc -shared -o hamming_weight.so hamming_weight.o $(LIBDIR) -lpq -lm

install: hamming_weight.so
	cp $? $(LIBINSTALL)
