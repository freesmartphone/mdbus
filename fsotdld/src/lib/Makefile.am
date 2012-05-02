include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsotdld.lib\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsotdl
modlibexec_LTLIBRARIES = libfsotdl.la
libfsotdl_la_SOURCES = \
	dbusinterfaces.vala \
	gpsdata.vala \
	gpsreceiver.vala \
	gpschannel.vala \
	locationprovider.vala \
	source.vala \
	$(NULL)
libfsotdl_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--header fsotdl.h \
	--library fsotdl-2.0 \
	$(NULL)
libfsotdl_la_CFLAGS = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
libfsotdl_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
libfsotdl_la_LDFLAGS = -no-undefined -avoid-version

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)

