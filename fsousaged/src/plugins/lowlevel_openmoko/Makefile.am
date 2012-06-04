include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsousage.lowlevel_openmoko\" \
	$(NULL)
AM_VALAFLAGS =


modlibexecdir = $(libdir)/cornucopia/modules/fsousage
modlibexec_LTLIBRARIES = lowlevel_openmoko.la
lowlevel_openmoko_la_SOURCES = plugin.vala
lowlevel_openmoko_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsousage-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
lowlevel_openmoko_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GEE_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
lowlevel_openmoko_la_LIBADD = \
	$(top_builddir)/src/lib/libfsousage.la \
	$(GEE_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
lowlevel_openmoko_la_LDFLAGS = -no-undefined -module -avoid-version
# lowlevel_openmoko_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
