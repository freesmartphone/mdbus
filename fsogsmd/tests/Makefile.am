include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(FSO_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(DBUS_LIBS) \
	$(FSO_LIBS) \
	../src/lib/libfsogsm.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogsm-2.0

TEST_PROGS += testatcommand
testatcommand_VALASOURCES = testatcommand.vala
testatcommand_SOURCES = testatcommand.c
$(testatcommand_SOURCES): $(testatcommand_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testatcommand_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testatcommand_VALASOURCES)

TEST_PROGS += testatparser
testatparser_VALASOURCES = testatparser.vala
testatparser_SOURCES = testatparser.c
$(testatparser_SOURCES): $(testatparser_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testatparser_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testatparser_VALASOURCES)

TEST_PROGS += testconversions
testconversions_VALASOURCES = testconversions.vala
testconversions_SOURCES = testconversions.c
$(testconversions_SOURCES): $(testconversions_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testconversions_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testconversions_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
