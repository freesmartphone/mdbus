include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsonetworkd.sharing\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsonetwork
modlibexec_LTLIBRARIES = sharing.la
sharing_la_SOURCES = plugin.vala
sharing_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	$(NULL)
sharing_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(NULL)
sharing_la_LIBADD = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(DBUS_LIBS) \
	$(NULL)
sharing_la_LDFLAGS = -no-undefined -module -avoid-version
# sharing_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
