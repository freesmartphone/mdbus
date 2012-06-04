include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.kernel_info\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = kernel_info.la
kernel_info_la_SOURCES = plugin.vala
kernel_info_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg linux \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
kernel_info_la_CFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
kernel_info_la_LIBADD = \
	$(FSO_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
kernel_info_la_LDFLAGS = -no-undefined -module -avoid-version
# kernel_info_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
