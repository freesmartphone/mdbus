include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.openmoko_powercontrol\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_FSORESOURCE
AM_VALAFLAGS += -D WANT_FSO_RESOURCE
endif

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = openmoko_powercontrol.la
openmoko_powercontrol_la_SOURCES = plugin.vala
openmoko_powercontrol_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0 \
	$(NULL)
openmoko_powercontrol_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
openmoko_powercontrol_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
openmoko_powercontrol_la_LDFLAGS = -no-undefined -module -avoid-version
# openmoko_powercontrol_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
