include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.modem_option_gtm601\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = modem_option_gtm601.la
modem_option_gtm601_la_SOURCES = \
	plugin.vala \
	commands.vala \
	mediators.vala \
	unsolicited.vala \
	pdphandler.vala \
	smshandler.vala \
	$(NULL)
modem_option_gtm601_la_VALAFLAGS = \
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
	$(DEBUG_VALAFLAGS) \
	$(NULL)
modem_option_gtm601_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
modem_option_gtm601_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsogsm.la \
	$(NULL)
modem_option_gtm601_la_LDFLAGS = -no-undefined -module -avoid-version
# modem_option_gtm601_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES =
