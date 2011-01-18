include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.n900_powercontrol\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0

if WANT_FSORESOURCE
VALAC_ARGS += -D WANT_FSO_RESOURCE
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = n900_powercontrol.la
n900_powercontrol_la_SOURCES = plugin.c
n900_powercontrol_la_VALASOURCES = plugin.vala
$(n900_powercontrol_la_SOURCES): $(n900_powercontrol_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
n900_powercontrol_la_LIBADD = $(progs_ldadd)
n900_powercontrol_la_LDFLAGS = -no-undefined -module -avoid-version
n900_powercontrol_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
