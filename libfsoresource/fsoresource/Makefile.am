include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	-DG_LOG_DOMAIN=\"fsoresource\" \
	$(NULL)

AM_VALAFLAGS = \
	$(NULL)

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CPPFLAGS += -ggdb -O0
endif

lib_LTLIBRARIES = libfsoresource.la

libfsoresource_la_SOURCES = \
	dbusresource.vala \
	$(NULL)

libfsoresource_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	--header fsoresource.h \
	--library fsoresource-2.0
	$(NULL)

libfsoresource_la_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(NULL)

libfsoresource_la_LIBADD = \
	$(GLIB_LIBS) \
	$(NULL)

fsoresourceincludedir = $(includedir)/fsoframework-2.0
fsoresourceinclude_HEADERS = fsoresource.h

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	fsoresource-2.0.vapi \
	fsoresource-2.0.deps \
	$(NULL)

BUILT_SOURCES = \
	fsoresource.h \
	fsoresource-2.0.vapi \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)
