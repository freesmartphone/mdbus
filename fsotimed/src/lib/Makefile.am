include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

BUILT_SOURCES = .vala.stamp fsotime-2.0.vapi

lib_LTLIBRARIES = \
	libfsotime.la
	$(NULL)

libfsotime_la_VALASOURCES = \
	dummy.vala \
	$(NULL)

libfsotime_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsotime_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsotimeincludedir = $(includedir)/fsoframework-2.0

fsotimeinclude_HEADERS = fsotime.h

$(BUILT_SOURCES): $(libfsotime_la_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) \
	            --vapidir $(top_srcdir)/vapi \
	            --pkg posix \
	            --pkg posixextra \
	            --pkg glib-2.0 \
	            --pkg gio-2.0 \
	            --header fsotime.h \
	            --library fsotime-2.0 $^
	touch $@

libfsotime_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsotime-2.0.vapi \
	fsotime-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsotime_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsotime_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsotime_la_SOURCES) \
	Makefile.in

