include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(ALSA_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.lib\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg linux \
	--pkg posix \
	--pkg alsa \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoresource-2.0 \
	--pkg fsoframework-2.0 \
	--header fsodevice.h \
	--library fsodevice-2.0

BUILT_SOURCES = .vala.stamp fsodevice-2.0.vapi

lib_LTLIBRARIES = \
	libfsodevice.la
	$(NULL)

libfsodevice_la_VALASOURCES = \
	accelerometer.vala \
	alsa.vala \
	audioplayer.vala \
	audiorouter.vala \
	dispatcher.vala \
	input.vala \
	powercontrol.vala \
	resource.vala \
	$(NULL)

libfsodevice_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsodevice_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsodeviceincludedir = $(includedir)/fsoframework-2.0

fsodeviceinclude_HEADERS = fsodevice.h

$(BUILT_SOURCES): $(libfsodevice_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsodevice_la_LIBADD = \
	$(FSO_LIBS) \
	$(ALSA_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsodevice-2.0.vapi \
	fsodevice-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsodevice_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsodevice_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsodevice_la_SOURCES) \
	Makefile.in

