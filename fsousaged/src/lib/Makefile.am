include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsousage.lib\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--header fsousage.h \
	--library fsousage-2.0

BUILT_SOURCES = .vala.stamp fsousage-2.0.vapi

lib_LTLIBRARIES = \
	libfsousage.la
	$(NULL)

libfsousage_la_VALASOURCES = \
	lowlevel.vala \
	$(NULL)

libfsousage_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsousage_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsousageincludedir = $(includedir)/fsoframework-2.0

fsousageinclude_HEADERS = fsousage.h

$(BUILT_SOURCES): $(libfsousage_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsousage_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsousage-2.0.vapi \
	fsousage-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsousage_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsousage_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsousage_la_SOURCES) \
	Makefile.in

