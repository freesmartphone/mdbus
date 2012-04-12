include $(top_srcdir)/Makefile.decl
NULL =

AM_CPPFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsoaudio\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CPPFLAGS += -ggdb -O0
endif

lib_LTLIBRARIES = libfsoaudio.la
libfsoaudio_la_SOURCES = \
	router.vala \
	alsa.vala \
	sessionhandler.vala \
	sessionpolicy.vala \
	streamcontrol.vala \
	$(NULL)
libfsoaudio_la_VALAFLAGS = \
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
	$(NULL)
libfsoaudio_la_CPPFLAGS = \
	$(FSO_CFLAGS) \
	$(ALSA_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
libfsoaudio_la_LIBADD = \
	$(FSO_LIBS) \
	$(GEE_LIBS) \
	$(GLIB_LIBS) \
	$(ALSA_LIBS) \
	$(NULL)
fsoaudioincludedir = $(includedir)/fsoframework-2.0
fsoaudioinclude_HEADERS = fsoaudio.h

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	fsoaudio-2.0.vapi \
	fsoaudio-2.0.deps \
	$(NULL)

BUILT_SOURCES = \
	fsoaudio.h \
	fsoaudio-2.0.vapi \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)
