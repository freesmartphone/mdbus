include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsogsm.pdp_nokia_isi\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = pdp_nokia_isi.la
pdp_nokia_isi_la_SOURCES = plugin.vala
pdp_nokia_isi_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--thread \
	--pkg thread \
	--pkg glib-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsogsm-2.0 \
	--pkg gisicomm-1.0
	$(DEBUG_VALAFLAGS) \
	$(NULL)
pdp_nokia_isi_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(ISI_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
pdp_nokia_isi_la_LIBADD = \
	$(top_builddir)/src/lib/libfsogsm.la \
	$(FSO_LIBS) \
	$(ISI_LIBS) \
	$(NULL)
pdp_nokia_isi_la_LDFLAGS = -no-undefined -module -avoid-version
# pdp_nokia_isi_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES =
