include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.gpio_input\" \
	$(NULL)
AM_VALAFLAGS =

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = gpio_input.la
gpio_input_la_SOURCES = plugin.vala
gpio_input_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg linux \
	--pkg fso-glib-1.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0 \
	$(NULL)
gpio_input_la_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
gpio_input_la_LIBADD = \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
gpio_input_la_LDFLAGS = -no-undefined -module -avoid-version
# gpio_input_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
