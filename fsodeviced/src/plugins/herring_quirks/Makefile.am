include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.herring_quirks\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_FSORESOURCE
AM_VALAFLAGS += -D WANT_FSO_RESOURCE
endif

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = herring_quirks.la
herring_quirks_la_SOURCES = \
	plugin.vala \
	resumehandler.vala \
	alsa.vala \
	powercontrol.vala \
	$(NULL)
herring_quirks_la_VALAFLAGS = \
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
herring_quirks_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
herring_quirks_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
herring_quirks_la_LDFLAGS = -no-undefined -module -avoid-version
# herring_quirks_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)

