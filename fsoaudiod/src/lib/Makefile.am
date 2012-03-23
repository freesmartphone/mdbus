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
	--pkg alsa \
	--pkg config \
	--header fsoaudio.h \
	--library fsoaudio-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = .vala.stamp fsoaudio-2.0.vapi

lib_LTLIBRARIES = \
	libfsoaudio.la
	$(NULL)

libfsoaudio_la_VALASOURCES = \
	router.vala \
	alsa.vala \
	sessionhandler.vala \
	sessionpolicy.vala \
	streamcontrol.vala \
	$(NULL)

libfsoaudio_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsoaudio_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsoaudioincludedir = $(includedir)/fsoframework-2.0

fsoaudioinclude_HEADERS = fsoaudio.h

$(BUILT_SOURCES): $(libfsoaudio_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsoaudio_la_LIBADD = \
	$(FSO_LIBS) \
	$(GEE_LIBS) \
	$(GLIB_LIBS) \
	$(ALSA_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsoaudio-2.0.vapi \
	fsoaudio-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsoaudio_la_VALASOURCES) \
	$(libfsoaudio_la_SOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsoaudio_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsoaudio_la_SOURCES) \
	Makefile.in

