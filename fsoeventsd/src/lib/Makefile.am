include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsoevents.lib\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg gee-1.0 \
	--header fsoevents.h \
	--library fsoevents-2.0 \
	$(NULL)

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = .vala.stamp fsoevents-2.0.vapi

lib_LTLIBRARIES = \
	libfsoevents.la
	$(NULL)

libfsoevents_la_VALASOURCES = \
	jsonreader.vala \
	basefilter.vala \
	logicalfilter.vala \
	andfilter.vala \
	orfilter.vala \
	basetrigger.vala \
	rule.vala \
	rulesparser.vala \
	$(NULL)

libfsoevents_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsoevents_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsoeventsincludedir = $(includedir)/fsoframework-2.0

fsoeventsinclude_HEADERS = fsoevents.h

$(BUILT_SOURCES): $(libfsoevents_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsoevents_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsoevents-2.0.vapi \
	fsoevents-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsoevents_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsoevents_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsoevents_la_SOURCES) \
	Makefile.in

