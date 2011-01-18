include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/3rdparty \
	$(FSO_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.powersupply_n900\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(FSO_LIBS) $(DBUS_LIBS) $(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg linux \
	--pkg i2c \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = powersupply_n900.la
powersupply_n900_la_SOURCES = plugin.c
powersupply_n900_la_VALASOURCES = plugin.vala
$(powersupply_n900_la_SOURCES): $(powersupply_n900_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
powersupply_n900_la_LIBADD = $(progs_ldadd)
powersupply_n900_la_LDFLAGS = -no-undefined -module -avoid-version
powersupply_n900_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
