include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.ambientlight_n900\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = ambientlight_n900.la
ambientlight_n900_la_SOURCES = plugin.vala
ambientlight_n900_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
ambientlight_n900_la_CFLAGS = \
	$(FSO_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
ambientlight_n900_la_LIBADD = \
	$(FSO_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
ambientlight_n900_la_LDFLAGS = -no-undefined -module -avoid-version
# ambientlight_n900_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
