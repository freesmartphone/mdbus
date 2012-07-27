include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/fsotest \
	$(GLIB_CFLAGS) \
	$(NULL)
AM_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsobasics \
	--vapidir $(top_srcdir)/fsotest \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsotest-2.0 \
	$(NULL)
LDADD = \
	$(GLIB_LIBS) \
	$(top_builddir)/fsotest/libfsotest.la

noinst_PROGRAMS = \
	testassert \
	testsignalwaiter \
	testtestcase \
	$(NULL)

TEST_PROGS += $(noinst_PROGRAMS)

testsignalwaiter_SOURCES = testsignalwaiter.vala
testassert_SOURCES = testassert.vala
testtestcase_SOURCES = testtestcase.vala

CLEANFILES = $(TEST_PROGS)
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
