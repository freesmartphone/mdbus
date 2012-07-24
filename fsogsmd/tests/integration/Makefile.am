include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(FSO_CFLAGS) \
	-g -DDEBUG \
	$(NULL)

noinst_PROGRAMS = integration_tests

LDADD = \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(FSO_LIBS) \
	$(top_builddir)/src/lib/libfsogsm.la \
	$(NULL)

AM_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsobasics-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogsm-2.0 \
	--pkg fsotest-2.0 \
	--pkg fsogsm3rdparty \
	-g \
	$(NULL)

integration_tests_SOURCES = integration-tests.vala

EXTRA_DIST += \
	fsogsmd.conf \
	phonesim-default.xml \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
