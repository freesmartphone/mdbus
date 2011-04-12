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
	libfsoaudio_session.la \
	$(NULL)

libfsoaudio_session_la_SOURCES = \
	alsa-wrapper.c \
	$(NULL)

libfsoaudio_session_la_LIBADD = \
	$(ALSA_LIBS) \
	$(NULL)

CLEANFILES = \
	$(NULL)

MAINTAINERCLEANFILES = \
	Makefile.in

