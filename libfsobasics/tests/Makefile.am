include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	-I../fsobasics \
	$(GLIB_CFLAGS) \
	$(NULL)

INCLUDES = \
	-I../fsobasics

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	../fsobasics/libfsobasics.la

VALAC_ARGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsobasics \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsobasics-2.0

#
# smartkeyfile test
#
TEST_PROGS += testsmartkeyfile
testsmartkeyfile_VALASOURCES = testsmartkeyfile.vala
testsmartkeyfile_SOURCES = testsmartkeyfile.c
$(testsmartkeyfile_SOURCES): $(testsmartkeyfile_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testsmartkeyfile_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testsmartkeyfile_VALASOURCES)

#
# logger test
#
TEST_PROGS += testlogger
testlogger_VALASOURCES = testlogger.vala
testlogger_SOURCES = testlogger.c
$(testlogger_SOURCES): $(testlogger_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testlogger_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testlogger_VALASOURCES)

#
# utilities test
#
TEST_PROGS += testutilities
testutilities_VALASOURCES = testutilities.vala
testutilities_SOURCES = testutilities.c
$(testutilities_SOURCES): $(testutilities_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testutilities_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testutilities_VALASOURCES)

#
#
#
CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
