include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

lib_LTLIBRARIES = \
	libfsotransport.la
	$(NULL)

libfsotransport_la_VALASOURCES = \
	transport.vala \
	$(NULL)

libfsotransport_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsotransport_la_VALASOURCES:.vala=.c) \
	$(libfsotransport_la_VALASOURCES:.vala=.h) \
	$(NULL)

fsotransportincludedir = $(includedir)/fsoframework-2.0/fsotransport

fsotransportinclude_HEADERS = \
	$(libfsotransport_la_VALASOURCES:.vala=.h) \
	$(NULL)

fsotransport-1.0.vapi .vala.stamp: $(libfsotransport_la_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) \
	            --vapidir ../vapi \
	            --pkg posix \
	            --pkg posixextra \
	            --pkg glib-2.0 \
	            --pkg gio-2.0 \
	            --library fsotransport-2.0 $^
	touch $@

libfsotransport_la_LIBADD = \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsotransport-2.0.vapi \
	$(NULL)

EXTRA_DIST += \
	$(libfsotransport_la_VALASOURCES) \
	fsotransport-2.0.vapi \
	fsotransport.vala.stamp

CLEANFILES = \
    $(BUILT_SOURCES) \
    $(libfsotransport_la_SOURCES) \
    $(NULL)

MAINTAINERCLEANFILES = \
	$(CLEANFILES) \
	Makefile.in
