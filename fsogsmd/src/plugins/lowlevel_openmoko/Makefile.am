include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.lowlevel_openmoko\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = lowlevel_openmoko.la
lowlevel_openmoko_la_SOURCES = plugin.vala
lowlevel_openmoko_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsogsm-2.0 \
	$(NULL)
lowlevel_openmoko_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(NULL)
lowlevel_openmoko_la_LIBADD = \
	$(top_builddir)/src/lib/libfsogsm.la \
	$(FSO_LIBS) \
	$(NULL)
lowlevel_openmoko_la_LDFLAGS = -no-undefined -module -avoid-version
# lowlevel_openmoko_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES =
