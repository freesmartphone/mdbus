include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	-I../fsotest \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(FSOBASICS_CFLAGS) \
	$(NULL)

INCLUDES = -I../fsotest

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(DBUS_LIBS) \
	$(FSOBASICS_LIBS) \
	../fsotest/libfsotest.la

VALAC_ARGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsotest \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg dbus-glib-1 \
	--pkg fsotest-2.0 \
	$(NULL)

TEST_PROGS += testsignalwaiter
testsignalwaiter_VALASOURCES = testsignalwaiter.vala
testsignalwaiter_SOURCES = testsignalwaiter.c
$(testsignalwaiter_SOURCES): $(testsignalwaiter_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testsignalwaiter_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testsignalwaiter_VALASOURCES)

TEST_PROGS += testassert
testassert_VALASOURCES = testassert.vala
testassert_SOURCES = testassert.c
$(testassert_SOURCES): $(testassert_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testassert_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testassert_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
