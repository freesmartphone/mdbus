include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GEE_LIBS) \
	$(top_srcdir)/src/lib/libfsoevents.la \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoevents-2.0 \
	$(NULL)

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

EXTRA_DIST += $(NULL)

TEST_PROGS += testjsonreader
testjsonreader_VALASOURCES = testjsonreader.vala
testjsonreader_SOURCES = testjsonreader.c
$(testjsonreader_SOURCES): $(testjsonreader_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testjsonreader_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testjsonreader_VALASOURCES)

TEST_PROGS += testrulesparser
testrulesparser_VALASOURCES = testrulesparser.vala
testrulesparser_SOURCES = testrulesparser.c
$(testrulesparser_SOURCES): $(testrulesparser_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testrulesparser_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testrulesparser_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
