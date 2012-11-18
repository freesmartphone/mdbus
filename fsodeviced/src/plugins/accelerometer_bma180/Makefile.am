include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.accelerometer_bma180\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = accelerometer_bma180.la
accelerometer_bma180_la_SOURCES = plugin.vala
accelerometer_bma180_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir ./ \
	--vapidir $(top_srcdir)/src/lib \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsodevice-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
accelerometer_bma180_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
accelerometer_bma180_la_LIBADD = \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(GLIB_LIBS) \
	$(FSO_LIBS) \
	$(NULL)
accelerometer_bma180_la_LDFLAGS = -no-undefined -module -avoid-version

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
