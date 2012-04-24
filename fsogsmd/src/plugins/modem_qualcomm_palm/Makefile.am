include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.modem_qualcomm_palm\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = modem_qualcomm_palm.la
modem_qualcomm_palm_la_SOURCES = \
 channel.vala \
 mediators.vala \
 unsolicited.vala \
 plugin.vala \
 callhandler.vala \
 data.vala \
 phonebookhandler.vala \
 sms.vala \
 consts.vala \
 mediatorhelpers.vala \
 mediators_debug.vala \
 mediators_device.vala \
 mediators_sim.vala \
 mediators_sms.vala \
 mediators_network.vala \
 mediators_call.vala \
 mediators_cb.vala \
 mediators_monitor.vala \
 mediators_vm.vala \
 mediators_pdp.vala \
 utils.vala \
 $(NULL)
modem_qualcomm_palm_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogsm-2.0 \
	--pkg msmcomm-specs-2.0 \
	$(NULL)
modem_qualcomm_palm_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(PALM_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)
modem_qualcomm_palm_la_LIBADD = \
	$(PALM_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_srcdir)/src/lib/libfsogsm.la
	$(NULL)
modem_qualcomm_palm_la_LDFLAGS = -no-undefined -module -avoid-version
# modem_qualcomm_palm_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES =
