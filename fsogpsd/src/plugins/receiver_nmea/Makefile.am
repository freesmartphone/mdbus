include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(DBUS_LIBS) \
	$(top_srcdir)/src/lib/libfsogps.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogps-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogps
modlibexec_LTLIBRARIES = receiver_nmea.la
receiver_nmea_la_SOURCES = plugin.c
receiver_nmea_la_VALASOURCES = plugin.vala
$(receiver_nmea_la_SOURCES): $(receiver_nmea_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
receiver_nmea_la_LIBADD = $(progs_ldadd)
receiver_nmea_la_LDFLAGS = -no-undefined -module -avoid-version
receiver_nmea_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
