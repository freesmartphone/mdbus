include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/fsotransport \
	$(GLIB_CFLAGS) \
	$(NULL)

LDADD = \
	$(GLIB_LIBS) \
	$(top_builddir)/fsotransport/libfsotransport.la \
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
	$(TEST_PROGS) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(addsuffix .c,$(noinst_PROGRAMS)) \
	testtransport_vala.stamp \
	testcommandqueue_vala.stamp \
	$(NULL)

EXTRA_DIST += \
	$(MAINTAINERCLEANFILES) \
	$(NULL)
