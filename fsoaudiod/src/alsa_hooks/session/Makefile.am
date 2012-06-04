include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsoaudio.alsa_hook\" \
	$(NULL)
AM_VALAFLAGS =


modlibexecdir = $(libdir)/alsa-lib
modlibexec_LTLIBRARIES = fsoaudio_session.la
fsoaudio_session_la_SOURCES = \
	plugin.vala \
	alsa-wrapper.c \
	$(NULL)
fsoaudio_session_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--pkg alsa \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
fsoaudio_session_la_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(ALSA_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
fsoaudio_session_la_LIBADD = \
	$(GLIB_LIBS) \
	$(ALSA_LIBS) \
	$(NULL)
fsoaudio_session_la_LDFLAGS = -no-undefined -module -avoid-version
# fsoaudio_session_la_LIBTOOLFLAGS = --tag=disable-static
