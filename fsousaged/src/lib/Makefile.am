include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsousage.lib\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsousage
modlibexec_LTLIBRARIES = libfsousage.la

libfsousage_la_SOURCES = lowlevel.vala
libfsousage_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--header fsousage.h \
	--library fsousage-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
libfsousage_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
libfsousage_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
libfsousage_la_LDFLAGS = -no-undefined -avoid-version

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	fsousage-2.0.vapi \
	fsousage.h \
	$(NULL)

