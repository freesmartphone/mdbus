include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(LIBNL_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

BUILT_SOURCES = .vala.stamp fsonetwork-2.0.vapi

lib_LTLIBRARIES = \
	libfsonetwork.la
	$(NULL)

libfsonetwork_la_VALASOURCES = \
	utils.vala \
	$(NULL)

libfsonetwork_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsonetwork_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsonetworkincludedir = $(includedir)/fsoframework-2.0

fsonetworkinclude_HEADERS = fsonetwork.h

$(BUILT_SOURCES): $(libfsonetwork_la_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) \
	            --vapidir $(top_srcdir)/vapi \
	            --pkg posix \
	            --pkg linux \
	            --pkg libnl-2.0 \
	            --pkg glib-2.0 \
	            --pkg gio-2.0 \
	            --header fsonetwork.h \
	            --library fsonetwork-2.0 $^
	touch $@

libfsonetwork_la_LIBADD = \
	$(FSO_LIBS) \
	$(LIBNL_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsonetwork-2.0.vapi \
	fsonetwork-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsonetwork_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsonetwork_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsonetwork_la_SOURCES) \
	Makefile.in

