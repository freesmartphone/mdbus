include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(XML_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodata.lib\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
    --vapidir $(top_srcdir)/vapi \
    --pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg libxml-2.0 \
	--pkg fsoframework-2.0 \
	--pkg config \
	--header fsodata.h \
	--library fsodata-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = .vala.stamp fsodata-2.0.vapi

lib_LTLIBRARIES = \
	libfsodata.la
	$(NULL)

libfsodata_la_VALASOURCES = \
	mbpi.vala \
	$(NULL)

libfsodata_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsodata_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsodataincludedir = $(includedir)/fsoframework-2.0

fsodatainclude_HEADERS = fsodata.h

$(BUILT_SOURCES): $(libfsodata_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsodata_la_LIBADD = \
	$(FSO_LIBS) \
	$(XML_LIBS) \
	$(GEE_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsodata-2.0.vapi \
	fsodata-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsodata_la_VALASOURCES) \
	$(libfsodata_la_SOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsodata_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsodata_la_SOURCES) \
	Makefile.in

