include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.kernel26_display\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = kernel26_display.la
kernel26_display_la_SOURCES = plugin.vala
kernel26_display_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	$(NULL)
kernel26_display_la_CFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(NULL)
kernel26_display_la_LIBADD = \
	$(FSO_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
kernel26_display_la_LDFLAGS = -no-undefined -module -avoid-version
# kernel26_display_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
