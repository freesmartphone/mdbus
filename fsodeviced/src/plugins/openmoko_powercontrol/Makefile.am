NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(FSO_LIBS) $(DBUS_LIBS) $(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = openmoko_powercontrol.la
openmoko_powercontrol_la_SOURCES = plugin.c
openmoko_powercontrol_la_VALASOURCES = plugin.vala
$(openmoko_powercontrol_la_SOURCES): $(openmoko_powercontrol_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
openmoko_powercontrol_la_LIBADD = $(progs_ldadd)
openmoko_powercontrol_la_LDFLAGS = -no-undefined -module -avoid-version
openmoko_powercontrol_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
