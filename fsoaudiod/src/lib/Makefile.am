include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsoaudio\" \
	$(NULL)
AM_VALAFLAGS =


modlibexecdir = $(libdir)/cornucopia/modules/fsoaudio
modlibexec_LTLIBRARIES = libfsoaudio.la
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
	$(DEBUG_VALAFLAGS) \
	$(NULL)
libfsoaudio_la_CFLAGS = \
	$(FSO_CFLAGS) \
	$(ALSA_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
libfsoaudio_la_LIBADD = \
	$(FSO_LIBS) \
	$(GEE_LIBS) \
	$(GLIB_LIBS) \
	$(ALSA_LIBS) \
	$(NULL)
libfsoaudio_la_LDFLAGS = -no-undefined -avoid-version

BUILT_SOURCES = \
	fsoaudio.h \
	fsoaudio-2.0.vapi \
	$(NULL)

EXTRA_DIST += $(BUILT_SOURCES)

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)
