include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	--header fsoresource.h \
	--library fsoresource-2.0

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

lib_LTLIBRARIES = \
	libfsoresource.la
	$(NULL)

libfsoresource_la_VALASOURCES = \
	dbusresource.vala \
	$(NULL)

libfsoresource_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsoresource_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsoresourceincludedir = $(includedir)/fsoframework-2.0

fsoresourceinclude_HEADERS = fsoresource.h

fsoresource-2.0.vapi .vala.stamp: $(libfsoresource_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsoresource_la_LIBADD = \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsoresource-2.0.vapi \
	fsoresource-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsoresource_la_VALASOURCES) \
	fsoresource-2.0.vapi \
	$(BUILT_SOURCES) \
	$(NULL)

CLEANFILES = \
    $(BUILT_SOURCES) \
    $(libfsoresource_la_SOURCES) \
    $(NULL)

MAINTAINERCLEANFILES = \
	$(CLEANFILES) \
	Makefile.in
