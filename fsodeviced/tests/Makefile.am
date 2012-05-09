include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(NULL)

AM_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsodevice-2.0 \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(FSO_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la

TEST_PROGS += testsoundsystem
testsoundsystem_SOURCES = testsoundsystem.vala
testsoundsystem_LDADD = $(progs_ldadd)

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
