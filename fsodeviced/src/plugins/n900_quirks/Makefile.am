include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.n900_quirks\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_FSORESOURCE
AM_VALAFLAGS += -D WANT_FSO_RESOURCE
endif

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = n900_quirks.la
n900_quirks_la_SOURCES = \
	plugin.vala \
	ambientlight.vala \
	powercontrol.vala \
	powersupply.vala \
	proximity.vala \
	$(NULL)
n900_quirks_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/src/lib \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsosystem-2.0 \
	--pkg fsodevice-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
n900_quirks_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
n900_quirks_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
n900_quirks_la_LDFLAGS = -no-undefined -module -avoid-version
# n900_quirks_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)

