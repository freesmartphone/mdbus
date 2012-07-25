include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/fsotransport \
	-I$(top_srcdir)/fsobasics \
	$(GLIB_CFLAGS) \
	$(LIBNL_CFLAGS) \
	$(NULL)

LDADD = \
	$(GLIB_LIBS) \
	$(top_builddir)/fsotransport/libfsotransport.la \
	$(top_builddir)/fsobasics/libfsobasics.la \
	$(NULL)

AM_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsotransport \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsotransport-2.0
	$(NULL)

noinst_PROGRAMS = \
	testtransport \
	testcommandqueue \
	$(NULL)

TEST_PROGS += $(noinst_PROGRAMS)

testtransport_SOURCES = \
	testtransport.vala \
	$(NULL)

testcommandqueue_SOURCES = \
	testcommandqueue.vala \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
