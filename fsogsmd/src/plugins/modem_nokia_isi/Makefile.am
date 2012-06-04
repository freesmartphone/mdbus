include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.modem_nokia_isi\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = modem_nokia_isi.la
modem_nokia_isi_la_SOURCES = \
	plugin.vala \
	isitransport.vala \
	channel.vala \
	unsolicited.vala \
	callhandler.vala \
	isicallmediators.vala \
	isidebugmediators.vala \
	isidevicemediators.vala \
	isimediatorhelpers.vala \
	isinetworkmediators.vala \
	isipdpmediators.vala \
	isisimmediators.vala \
	isismsmediators.vala \
	$(NULL)
modem_nokia_isi_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogsm-2.0 \
	--pkg gisicomm-1.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
modem_nokia_isi_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(ISI_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
modem_nokia_isi_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(ISI_LIBS) \
	$(top_builddir)/src/lib/libfsogsm.la
	$(NULL)
modem_nokia_isi_la_LDFLAGS = -no-undefined -module -avoid-version
# modem_nokia_isi_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES =
