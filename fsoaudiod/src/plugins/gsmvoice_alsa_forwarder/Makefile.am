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

modlibexecdir = $(libdir)/cornucopia/modules/fsoaudio
modlibexec_LTLIBRARIES = gsmvoice_alsa_forwarder.la
gsmvoice_alsa_forwarder_la_SOURCES = \
	plugin.vala \
	alsaloop.c \
	pcmjob.c \
	control.c \
	$(NULL)
gsmvoice_alsa_forwarder_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsoaudio-2.0
	$(NULL)
gsmvoice_alsa_forwarder_la_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/vapi \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-lsamplerate -D_GNU_SOURCE \
	-DHAVE_SAMPLERATE_H \
	$(NULL)
gsmvoice_alsa_forwarder_la_LIBADD = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsoaudio.la
	$(NULL)
gsmvoice_alsa_forwarder_la_LDFLAGS = -no-undefined -module -avoid-version -lm
# gsmvoice_alsa_forwarder_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	alsaloop.c \
	control.c \
	pcmjob.c \
	alsaloop.h \
	$(NULL)
