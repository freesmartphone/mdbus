include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
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
	$(NULL)

AM_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsotest-2.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsoresource-2.0 \
	--pkg fso-glib-1.0 \
	-g \
	$(NULL)

integration_tests_SOURCES = \
	main.vala \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
