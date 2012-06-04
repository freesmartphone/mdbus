include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.pdp_ppp_internal\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = pdp_ppp_internal.la
pdp_ppp_internal_la_SOURCES = plugin.vala
pdp_ppp_internal_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--thread \
	--pkg thread \
	--pkg glib-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsogsm-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
pdp_ppp_internal_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	-I$(top_srcdir)/src/3rdparty/ppp \
	$(FSO_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
pdp_ppp_internal_la_LIBADD = \
	$(top_builddir)/src/lib/libfsogsm.la \
	$(FSO_LIBS) \
	$(NULL)
pdp_ppp_internal_la_LDFLAGS = -no-undefined -module -avoid-version
# pdp_ppp_internal_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES =
