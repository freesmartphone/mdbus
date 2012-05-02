include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsotdld.alarm\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsotdl
modlibexec_LTLIBRARIES = alarm.la
alarm_la_SOURCES = plugin.vala
alarm_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	$(NULL)
alarm_la_CFLAGS = \
	$(FSO_GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)
alarm_la_LIBADD = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsotdl.la \
	$(NULL)
alarm_la_LDFLAGS = -no-undefined -module -avoid-version
# alarm_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
