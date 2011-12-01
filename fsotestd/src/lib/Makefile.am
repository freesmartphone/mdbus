include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(ALSA_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg config \
	--header fsotest.h \
	--library fsotest-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = .vala.stamp fsotest-2.0.vapi

lib_LTLIBRARIES = \
	libfsotest.la
	$(NULL)

libfsotest_la_VALASOURCES = \
	dummy.vala \
	$(NULL)

libfsotest_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsotest_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsotestincludedir = $(includedir)/fsoframework-2.0

fsotestinclude_HEADERS = fsotest.h

$(BUILT_SOURCES): $(libfsotest_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsotest_la_LIBADD = \
	$(FSO_LIBS) \
	$(GEE_LIBS) \
	$(GLIB_LIBS) \
	$(ALSA_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsotest-2.0.vapi \
	fsotest-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsotest_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsotest_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsotest_la_SOURCES) \
	Makefile.in

