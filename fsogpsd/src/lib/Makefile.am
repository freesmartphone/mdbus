include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg posixextra \
	--pkg dbus-glib-1 \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--header fsogps.h \
	--library fsogps-2.0

BUILT_SOURCES = .vala.stamp fsogps-2.0.vapi

lib_LTLIBRARIES = \
	libfsogps.la
	$(NULL)

libfsogps_la_VALASOURCES = \
	receiver.vala \
	$(NULL)

libfsogps_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsogps_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsogpsincludedir = $(includedir)/fsoframework-2.0
fsogpsinclude_HEADERS = fsogps.h

$(BUILT_SOURCES): $(libfsogps_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsogps_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsogps-2.0.vapi \
	fsogps-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsogps_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsogps_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsogps_la_SOURCES) \
	Makefile.in

