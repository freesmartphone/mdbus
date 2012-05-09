include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.kernel26_rfkill\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_FSORESOURCE
AM_VALAFLAGS += -D WANT_FSO_RESOURCE
endif

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = kernel26_rfkill.la
kernel26_rfkill_la_SOURCES = plugin.vala
kernel26_rfkill_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0 \
	--pkg fsosystem-2.0 \
	$(NULL)
kernel26_rfkill_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
kernel26_rfkill_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
kernel26_rfkill_la_LDFLAGS = -no-undefined -module -avoid-version
# kernel26_rfkill_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
