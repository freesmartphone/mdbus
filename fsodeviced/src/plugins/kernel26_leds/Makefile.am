NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(FSO_LIBS) $(DBUS_LIBS) $(top_srcdir)/src/lib/libfsodevice.la

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = kernel26_leds.la
kernel26_leds_la_SOURCES = plugin.c plugin.h
kernel26_leds_la_VALASOURCES = plugin.vala
$(kernel26_leds_la_SOURCES): $(kernel26_leds_la_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg fsoframework-2.0 $^
	touch $@
kernel26_leds_la_LIBADD = $(progs_ldadd)
kernel26_leds_la_LDFLAGS = -no-undefined -module -avoid-version
kernel26_leds_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
