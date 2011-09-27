include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsopreferences.lib\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--header fsopreferences.h \
	--library fsopreferences-2.0

BUILT_SOURCES = .vala.stamp fsopreferences-2.0.vapi

lib_LTLIBRARIES = \
	libfsopreferences.la
	$(NULL)

libfsopreferences_la_VALASOURCES = \
	serviceprovider.vala \
	$(NULL)

libfsopreferences_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsopreferences_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsopreferencesincludedir = $(includedir)/fsoframework-2.0

fsopreferencesinclude_HEADERS = fsopreferences.h

$(BUILT_SOURCES): $(libfsopreferences_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsopreferences_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsopreferences-2.0.vapi \
	fsopreferences-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsopreferences_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsopreferences_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsopreferences_la_SOURCES) \
	Makefile.in

