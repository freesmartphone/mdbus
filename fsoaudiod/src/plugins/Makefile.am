include $(top_srcdir)/Makefile.decl
NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	manager \
	\
	router_alsa \
	\
	streamcontrol_alsa \
	sessionpolicy_default \
	\
	system_integration \
	\
	$(NULL)

if WANT_CMTSPEECHDATA
SUBDIRS += gsmvoice_alsa_cmtspeechdata
endif

if WANT_SAMPLERATE
SUBDIRS += gsmvoice_alsa_forwarder
endif
