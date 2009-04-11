include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(FSO_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(DBUS_LIBS) \
	$(FSO_LIBS) \
	../src/lib/libfsogsm.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg dbus-glib-1 \
	--pkg fsoframework-2.0 \
	--pkg fsogsm-2.0

TEST_PROGS += testatcommand
testatcommand_VALASOURCES = testatcommand.vala
testatcommand_SOURCES = testatcommand.c testatcommand.h
$(testatcommand_SOURCES): $(testatcommand_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testatcommand_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testatcommand_VALASOURCES)

TEST_PROGS += testcommandqueue
testcommandqueue_VALASOURCES = testcommandqueue.vala
testcommandqueue_SOURCES = testcommandqueue.c testcommandqueue.h
$(testcommandqueue_SOURCES): $(testcommandqueue_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testcommandqueue_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testcommandqueue_VALASOURCES)

TEST_PROGS += testparser
testparser_VALASOURCES = testparser.vala
testparser_SOURCES = testparser.c testparser.h
$(testparser_SOURCES): $(testparser_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testparser_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testparser_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
