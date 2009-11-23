NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(DBUS_LIBS) \
	$(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg dbus-glib-1 \
	--pkg linux \
	--pkg fso-glib-1.0 \
	--pkg fsoresource-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = accelerometer.la
accelerometer_la_SOURCES = plugin.c
accelerometer_la_VALASOURCES = plugin.vala
$(accelerometer_la_SOURCES): $(accelerometer_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
accelerometer_la_LIBADD = $(progs_ldadd)
accelerometer_la_LDFLAGS = -no-undefined -module -avoid-version
accelerometer_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
