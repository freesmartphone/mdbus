include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.player_canberra\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = player_canberra.la
player_canberra_la_SOURCES = plugin.vala
player_canberra_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0 \
	--pkg libcanberra \
	$(NULL)
player_canberra_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(CANBERRA_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
player_canberra_la_LIBADD = \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(CANBERRA_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
player_canberra_la_LDFLAGS = -no-undefined -module -avoid-version
# player_canberra_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
