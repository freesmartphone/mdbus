include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-D G_LOG_DOMAIN=\"fsotest\" \
	$(NULL)
AM_VALAFLAGS =


lib_LTLIBRARIES = libfsotest.la

libfsotest_la_SOURCES = \
	assert.vala \
	signalwaiter.vala \
	asynchelpers.vala \
	testcase.vala \
	$(NULL)
libfsotest_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg glib-2.0-ext \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg config \
	--header fsotest.h \
	--library fsotest-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
libfsotest_la_CFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
libfsotest_la_LIBADD = \
	$(GLIB_LIBS) \
	$(NULL)
libfsotest_la_LDFLAGS = \
	$(AM_LDFLAGS) \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	$(NULL)

fsotestincludedir = $(includedir)/fsotest-2.0
fsotestinclude_HEADERS = fsotest.h

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	fsotest-2.0.vapi \
	fsotest-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	fsotest-2.0.vapi \
	fsotest-2.0.deps \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	fsotest-2.0.vapi \
	fsotest.h \
	Makefile.in
