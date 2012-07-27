include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	-DG_LOG_DOMAIN=\"fsoresource\" \
	$(NULL)

AM_VALAFLAGS = \
	$(NULL)


lib_LTLIBRARIES = libfsoresource.la

libfsoresource_la_SOURCES = \
	dbusresource.vala \
	$(NULL)

libfsoresource_la_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsobasics \
	--vapidir $(top_srcdir)/fsoframework \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	--header fsoresource.h \
	--library fsoresource-2.0
	$(DEBUG_VALAFLAGS) \
	$(NULL)

libfsoresource_la_CFLAGS = \
	$(AM_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(LIBNL_CFLAGS) \
	$(FSO_GLIB_CFLAGS) \
	-I$(top_srcdir)/fsobasics \
	-I$(top_srcdir)/fsoframework \
	$(NULL)

libfsoresource_la_LIBADD = \
	$(GLIB_LIBS) \
	$(FSO_GLIB_LIBS) \
	$(NULL)
libfsoresource_la_LDFLAGS = \
	$(AM_LDFLAGS) \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	$(NULL)

fsoresourceincludedir = $(includedir)/fsoframework-2.0
fsoresourceinclude_HEADERS = fsoresource.h

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	fsoresource-2.0.vapi \
	fsoresource-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	fsoresource-2.0.pc.in \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = fsoresource-2.0.pc

BUILT_SOURCES = \
	fsoresource.h \
	fsoresource-2.0.vapi \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)
