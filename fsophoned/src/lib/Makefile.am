include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
    --vapidir $(top_srcdir)/vapi \
    --pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg config \
	--header fsophone.h \
	--library fsophone-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = .vala.stamp fsophone-2.0.vapi

lib_LTLIBRARIES = \
	libfsophone.la
	$(NULL)

libfsophone_la_VALASOURCES = \
	dummy.vala \
	$(NULL)

libfsophone_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsophone_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsophoneincludedir = $(includedir)/fsoframework-2.0

fsophoneinclude_HEADERS = fsophone.h

$(BUILT_SOURCES): $(libfsophone_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsophone_la_LIBADD = \
	$(FSO_LIBS) \
	$(GEE_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsophone-2.0.vapi \
	fsophone-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsophone_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsophone_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsophone_la_SOURCES) \
	Makefile.in

