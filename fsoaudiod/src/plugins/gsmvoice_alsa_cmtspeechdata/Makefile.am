include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsoaudio\" \
	$(NULL)
AM_VALAFLAGS =


modlibexecdir = $(libdir)/cornucopia/modules/fsoaudio
modlibexec_LTLIBRARIES = gsmvoice_alsa_cmtspeechdata.la
gsmvoice_alsa_cmtspeechdata_la_SOURCES = \
	plugin.vala \
	cmthandler.vala \
	$(NULL)
gsmvoice_alsa_cmtspeechdata_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsoaudio-2.0 \
	--pkg libcmtspeechdata \
	--pkg alsa \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
gsmvoice_alsa_cmtspeechdata_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/vapi \
	$(CMTSPEECHDATA_CFLAGS) \
	$(FSO_GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
gsmvoice_alsa_cmtspeechdata_la_LIBADD = \
	$(CMTSPEECHDATA_LIBS) \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsoaudio.la
	$(NULL)
gsmvoice_alsa_cmtspeechdata_la_LDFLAGS = -no-undefined -module -avoid-version
# gsmvoice_alsa_cmtspeechdata_la_LIBTOOLFLAGS = --tag=disable-static
