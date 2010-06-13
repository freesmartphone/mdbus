include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--header fsotdl.h \
	--library fsotdl-2.0

BUILT_SOURCES = .vala.stamp fsotdl-2.0.vapi

lib_LTLIBRARIES = \
	libfsotdl.la
	$(NULL)

libfsotdl_la_VALASOURCES = \
	gpsdata.vala \
	gpsreceiver.vala \
	gpschannel.vala \
	locationprovider.vala \
	source.vala \
	$(NULL)

libfsotdl_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsotdl_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsotdlincludedir = $(includedir)/fsoframework-2.0

fsotdlinclude_HEADERS = fsotdl.h

$(BUILT_SOURCES): $(libfsotdl_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsotdl_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsotdl-2.0.vapi \
	fsotdl-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsotdl_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsotdl_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsotdl_la_SOURCES) \
	Makefile.in

