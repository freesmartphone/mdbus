include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.player_gstreamer\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = player_gstreamer.la
player_gstreamer_la_SOURCES = plugin.vala
player_gstreamer_la_VALAFLAGS = \
	--thread \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg thread \
	--pkg gstreamer-0.10 \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0 \
	$(NULL)
player_gstreamer_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GSTREAMER_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
player_gstreamer_la_LIBADD = \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(GSTREAMER_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
player_gstreamer_la_LDFLAGS = -no-undefined -module -avoid-version
# player_gstreamer_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
