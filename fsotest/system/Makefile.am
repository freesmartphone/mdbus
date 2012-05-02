include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(NULL)
AM_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsosystem-2.0 \
	$(NULL)
LDADD = \
	$(GLIB_LIBS) \
	$(FSO_LIBS) \
	$(NULL)

noinst_PROGRAMS = \
	testnetwork \
	testmodules \
	testpath \
	$(NULL)
TEST_PROGS += $(noinst_PROGRAMS)

testmodules_SOURCES = testmodules.vala
testnetwork_SOURCES = testnetwork.vala
testpath_SOURCES = testpath.vala

CLEANFILES = $(TEST_PROGS)
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
