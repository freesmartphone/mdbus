include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.router_qdsp5\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = router_qdsp5.la
router_qdsp5_la_SOURCES = plugin.vala playwav2.c
router_qdsp5_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/src/plugins/router_qdsp5 \
	--pkg playwav2 \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
router_qdsp5_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
router_qdsp5_la_LIBADD = \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
router_qdsp5_la_LDFLAGS = -no-undefined -module -avoid-version
# router_qdsp5_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	playwav2.vapi \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
