include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

BUILT_SOURCES = .vala.stamp fsodevice-2.0.vapi

lib_LTLIBRARIES = \
	libfsodevice.la
	$(NULL)

libfsodevice_la_VALASOURCES = \
	dummy.vala \
	$(NULL)

libfsodevice_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsodevice_la_VALASOURCES:.vala=.c) \
	$(libfsodevice_la_VALASOURCES:.vala=.h) \
	$(NULL)

fsodeviceincludedir = $(includedir)/fsoframework-2.0/fsodevice

fsodeviceinclude_HEADERS = \
	$(libfsodevice_la_VALASOURCES:.vala=.h) \
	$(NULL)

$(BUILT_SOURCES): $(libfsodevice_la_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) \
	            --vapidir $(top_srcdir)/vapi \
	            --pkg posix \
	            --pkg posixextra \
	            --pkg glib-2.0 \
	            --pkg gio-2.0 \
	            --library fsodevice-2.0 $^
	touch $@

libfsodevice_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsodevice-2.0.vapi \
	$(NULL)

EXTRA_DIST += \
	$(libfsodevice_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsodevice_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsodevice_la_SOURCES) \
	Makefile.in

