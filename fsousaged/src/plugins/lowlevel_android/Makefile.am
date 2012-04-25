include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsousage.lowlevel_android\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

modlibexecdir = $(libdir)/cornucopia/modules/fsousage
modlibexec_LTLIBRARIES = lowlevel_android.la
lowlevel_android_la_SOURCES = plugin.vala
lowlevel_android_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsousage-2.0
	$(NULL)
lowlevel_android_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GEE_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
lowlevel_android_la_LIBADD = \
	$(top_builddir)/src/lib/libfsousage.la \
	$(GEE_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
lowlevel_android_la_LDFLAGS = -no-undefined -module -avoid-version
# lowlevel_android_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
