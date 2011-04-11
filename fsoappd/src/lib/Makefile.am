include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsoapp.lib\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg config \
	--header fsoapp.h \
	--library fsoapp-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = .vala.stamp fsoapp-2.0.vapi

lib_LTLIBRARIES = \
	libfsoapp.la
	$(NULL)

libfsoapp_la_VALASOURCES = \
	abstractwindowcontroller.vala \
	$(NULL)

libfsoapp_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsoapp_la_VALASOURCES:.vala=.c) \
	$(THIRDPARTY_SOURCES) \
	$(NULL)

fsoappincludedir = $(includedir)/fsoframework-2.0
fsoappinclude_HEADERS = fsoapp.h

$(BUILT_SOURCES): $(libfsoapp_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsoapp_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(GSMMUX_LIBS) \
	$(THIRDPARTY_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsoapp-2.0.vapi \
	fsoapp-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsoapp_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
        $(libfsoapp_la_VALASOURCES:.vala=.c) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(CLEANFILES) \
	Makefile.in
