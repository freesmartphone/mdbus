include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.accelerometer\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = accelerometer.la
accelerometer_la_SOURCES = plugin.vala
accelerometer_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg linux \
	--pkg fso-glib-1.0 \
	--pkg fsoresource-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0
	$(NULL)
accelerometer_la_CFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
accelerometer_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
accelerometer_la_LDFLAGS = -no-undefined -module -avoid-version
# accelerometer_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
