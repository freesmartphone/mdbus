include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.lib\" \
	$(NULL)
AM_VALAFLAGS =


modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = libfsogsm.la
libfsogsm_la_SOURCES = \
	at/atchannel.vala \
	at/atcommand.vala \
	at/atcommands.vala \
	at/atcommandqueue.vala \
	at/atcallmediators.vala \
	at/atcbmediators.vala \
	at/atdebugmediators.vala \
	at/atdevicemediators.vala \
	at/atmediatorhelpers.vala \
	at/atmonitormediators.vala \
	at/atnetworkmediators.vala \
	at/atpdpmediators.vala \
	at/atsimmediators.vala \
	at/atsmsmediators.vala \
	at/atvmmediators.vala \
	at/atparser.vala \
	at/atpdp.vala \
	at/atsms.vala \
	at/atunsolicited.vala \
	at/atphonebook.vala \
	at/atresultiter.vala \
	\
	call.vala \
	codes.vala \
	consts.vala \
	channel.vala \
	lowlevel.vala \
	mediator.vala \
	mediatorhelpers.vala \
	modem.vala \
	phonebook.vala \
	pdp.vala \
	sms.vala \
	smsstorage.vala \
	watchdog.vala \
	serviceprovider.vala \
	mbpi.vala \
	callhandler.vala \
	calldriver.vala \
	\
	$(top_srcdir)/src/3rdparty/conversions.c \
	$(top_srcdir)/src/3rdparty/smsutil.c \
	$(top_srcdir)/src/3rdparty/storage.c \
	$(top_srcdir)/src/3rdparty/util.c \
	\
	$(top_srcdir)/src/3rdparty/ppp/crc-ccitt.c \
	$(top_srcdir)/src/3rdparty/ppp/gathdlc.c \
	$(top_srcdir)/src/3rdparty/ppp/gatio.c \
	$(top_srcdir)/src/3rdparty/ppp/gatppp.c \
	$(top_srcdir)/src/3rdparty/ppp/gatutil.c \
	$(top_srcdir)/src/3rdparty/ppp/ppp_auth.c \
	$(top_srcdir)/src/3rdparty/ppp/ppp_cp.c \
	$(top_srcdir)/src/3rdparty/ppp/ppp_ipcp.c \
	$(top_srcdir)/src/3rdparty/ppp/ppp_lcp.c \
	$(top_srcdir)/src/3rdparty/ppp/ppp_net.c \
	$(top_srcdir)/src/3rdparty/ppp/ringbuffer.c \
	$(NULL)
libfsogsm_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsosystem-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogsm3rdparty \
	--pkg libxml-2.0 \
	--pkg config \
	--header fsogsm.h \
	--library fsogsm-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
libfsogsm_la_CFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/src/3rdparty \
	-I$(top_srcdir)/src/3rdparty/ppp \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GSMMUX_CFLAGS) \
	$(XML_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)

if WANT_MUX
libfsogsm_la_VALAFLAGS += --pkg gsm0710mux-1.0
libfsogsm_la_SOURCES += muxtransport.vala
endif

libfsogsm_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(GSMMUX_LIBS) \
	$(THIRDPARTY_LIBS) \
	$(XML_LIBS) \
	$(NULL)
libfsogsm_la_LDFLAGS = -no-undefined -avoid-version

EXTRA_DIST += \
	fsogsm3rdparty.deps \
	fsogsm3rdparty.vapi \
	fsogsm-2.0.deps \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	fsogsm.h \
	fsogsm-2.0.vapi \
	$(NULL)
