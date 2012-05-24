include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.modem_samsung\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = modem_samsung.la
modem_samsung_la_SOURCES = \
 samsungtransport.vala \
 plugin.vala \
 commandhandler.vala \
 channel.vala \
 rfs.vala \
 unsolicited.vala \
 modemstate.vala \
 mediators_sim.vala \
 mediators_device.vala \
 mediators_network.vala \
 mediators_pdp.vala \
 mediators_sms.vala \
 pdphandler.vala \
 mediators_call.vala \
 callhandler.vala \
 soundhandler.vala \
 smshandler.vala \
 utils.vala \
 $(NULL)
modem_samsung_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/src/plugins/modem_samsung \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsosystem-2.0 \
	--pkg fsogsm-2.0 \
	--pkg samsung-ipc-1.0 \
	--pkg samsung-modemctl \
	$(NULL)
modem_samsung_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	-I$(top_srcdir)/src/plugins/modem_samsung/include \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(SAMSUNG_CFLAGS) \
	$(NULL)
modem_samsung_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(SAMSUNG_LIBS) \
	$(top_builddir)/src/lib/libfsogsm.la
	$(NULL)
modem_samsung_la_LDFLAGS = -no-undefined -module -avoid-version
# modem_samsung_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += include/samsung_modem_ctl.h

CLEANFILES =
MAINTAINERCLEANFILES =
