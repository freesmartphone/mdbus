include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.backlight_omappanel\" \
	$(NULL)

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = backlight_omappanel.la
backlight_omappanel_la_SOURCES = plugin.vala
backlight_omappanel_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
backlight_omappanel_la_CFLAGS = \
	$(FSO_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
backlight_omappanel_la_LIBADD = \
	$(FSO_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
backlight_omappanel_la_LDFLAGS = -no-undefined -module -avoid-version
# backlight_omappanel_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
