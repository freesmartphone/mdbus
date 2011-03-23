include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	$(ALSA_CFLAGS) \
	$(NULL)

if WANT_DEBUG
AM_CFLAGS += -ggdb -O0
endif

lib_LTLIBRARIES = \
	libfsoaudio_request_session.la \
	libfsoaudio_release_session.la \
	$(NULL)

libfsoaudio_request_session_la_SOURCES = \
	request-session.c \
	$(NULL)

libfsoaudio_request_session_la_LIBADD = \
	$(ALSA_LIBS) \
	$(NULL)

libfsoaudio_release_session_la_SOURCES = \
	release-session.c \
	$(NULL)

libfsoaudio_release_session_la_LIBADD = \
	$(ALSA_LIBS) \
	$(NULL)

CLEANFILES = \
	$(NULL)

MAINTAINERCLEANFILES = \
	Makefile.in

