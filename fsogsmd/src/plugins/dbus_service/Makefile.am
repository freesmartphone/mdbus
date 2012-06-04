include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.dbus_service\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = dbus_service.la
dbus_service_la_SOURCES = \
	plugin.vala \
	service.vala \
	servicemanager.vala \
	modemfactory.vala \
	resource.vala \
	info_service.vala \
	device_powersupply_service.vala \
	device_rtc_service.vala \
	gsm_debug_service.vala \
	gsm_device_service.vala \
	gsm_sim_service.vala \
	gsm_sms_service.vala \
	gsm_network_service.vala \
	gsm_call_service.vala \
	gsm_hz_service.vala \
	gsm_cb_service.vala \
	gsm_voicemail_service.vala \
	gsm_monitor_service.vala \
	gsm_pdp_service.vala \
	$(NULL)
dbus_service_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsoresource-2.0 \
	--pkg fsogsm-2.0 \
	$(NULL)
dbus_service_la_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)
dbus_service_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsogsm.la \
	$(NULL)
dbus_service_la_LDFLAGS = -no-undefined -module -avoid-version
# dbus_service_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES =
