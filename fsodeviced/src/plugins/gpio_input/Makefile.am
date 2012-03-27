include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.gpio_input\" \
	$(NULL)

progs_ldadd = \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

VALAC_ARGS = \
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
	--pkg fsodevice-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = gpio_input.la
gpio_input_la_SOURCES = plugin.c
gpio_input_la_VALASOURCES = plugin.vala
$(gpio_input_la_SOURCES): $(gpio_input_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
gpio_input_la_LIBADD = $(progs_ldadd)
gpio_input_la_LDFLAGS = -no-undefined -module -avoid-version
gpio_input_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(gpio_input_la_VALASOURCES) \
	$(gpio_input_la_SOURCES) \
	$(NULL)

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
