include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.connman\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

modlibexecdir = $(libdir)/connman/plugins
modlibexec_LTLIBRARIES = fsogsm.la
fsogsm_la_SOURCES = connman-wrapper.c plugin.vala modemhandler.vala
fsogsm_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg connman \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	$(NULL)
fsogsm_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(CONNMAN_CFLAGS) \
	$(NULL)
fsogsm_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(CONNMAN_LIBS) \
	$(top_builddir)/src/lib/libfsogsm.la \
	$(NULL)
fsogsm_la_LDFLAGS = -no-undefined -module -avoid-version
# fsogsm_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES =
