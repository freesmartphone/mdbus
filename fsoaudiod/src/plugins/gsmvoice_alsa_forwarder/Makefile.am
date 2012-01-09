include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/vapi \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-lsamplerate -D_GNU_SOURCE \
	-DHAVE_SAMPLERATE_H \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_srcdir)/src/lib/libfsoaudio.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsoaudio-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsoaudio
modlibexec_LTLIBRARIES = gsmvoice_alsa_forwarder.la
gsmvoice_alsa_forwarder_la_SOURCES = plugin.c alsaloop.c pcmjob.c control.c
gsmvoice_alsa_forwarder_la_VALASOURCES = plugin.vala
$(gsmvoice_alsa_forwarder_la_SOURCES): $(gsmvoice_alsa_forwarder_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
gsmvoice_alsa_forwarder_la_LIBADD = $(progs_ldadd)
gsmvoice_alsa_forwarder_la_LDFLAGS = -no-undefined -module -avoid-version -lm
gsmvoice_alsa_forwarder_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    plugin.c \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
