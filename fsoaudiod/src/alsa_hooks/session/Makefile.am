include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(ALSA_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsoaudio.alsa_hook\" \
	$(NULL)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(ALSA_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--pkg alsa \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	$(NULL)

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/alsa-lib
modlibexec_LTLIBRARIES = fsoaudio_session.la
fsoaudio_session_la_SOURCES = alsa-wrapper.c plugin.c
fsoaudio_session_la_VALASOURCES = plugin.vala
$(fsoaudio_session_la_SOURCES): $(fsoaudio_session_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
fsoaudio_session_la_LIBADD = $(progs_ldadd)
fsoaudio_session_la_LDFLAGS = -no-undefined -module -avoid-version
fsoaudio_session_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(fsoaudio_session_la_VALASOURCES) \
	$(fsoaudio_session_la_SOURCES) \
	$(NULL)

CLEANFILES = \
    $(fsoaudio_session_la_VALASOURCES:.vala=.c) \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
