include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(FSOBASICS_CFLAGS) \
	-D G_LOG_DOMAIN=\"fsotest\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsobasics-2.0 \
	--pkg config \
	--header fsotest.h \
	--library fsotest-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = fsotest.vala.stamp

lib_LTLIBRARIES = \
	libfsotest.la
	$(NULL)

libfsotest_la_VALASOURCES = \
	assert.vala \
	signalwaiter.vala \
	asynchelpers.vala \
	testcase.vala \
	$(NULL)

libfsotest_la_SOURCES = \
	fsotest.vala.stamp \
	$(libfsotest_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsotestincludedir = $(includedir)/fsotest-2.0
fsotestinclude_HEADERS = fsotest.h

fsotest-2.0.vapi fsotest.vala.stamp: $(libfsotest_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsotest_la_LIBADD = \
	$(GLIB_LIBS) \
	$(FSOBASICS_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsotest-2.0.vapi \
	fsotest-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsotest_la_VALASOURCES) \
	fsotest-2.0.vapi \
	fsotest-2.0.deps \
	fsotest.vala.stamp

CLEANFILES = \
    $(BUILT_SOURCES) \
    $(libfsotest_la_SOURCES) \
    $(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsotest_la_SOURCES) \
	Makefile.in

