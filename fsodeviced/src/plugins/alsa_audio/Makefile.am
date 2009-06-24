NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(CANBERRA_CFLAGS) \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_srcdir)/src/lib/libfsodevice.la \
	$(CANBERRA_LIBS) \
	$(FSO_LIBS) \
	$(DBUS_LIBS) \
	$(GEE_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0 \
	--pkg libcanberra

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = alsa_audio.la
alsa_audio_la_SOURCES = plugin.c
alsa_audio_la_VALASOURCES = plugin.vala
$(alsa_audio_la_SOURCES): $(alsa_audio_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
alsa_audio_la_LIBADD = $(progs_ldadd)
alsa_audio_la_LDFLAGS = -no-undefined -module -avoid-version
alsa_audio_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
