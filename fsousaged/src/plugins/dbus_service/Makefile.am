NULL =

if PERSISTENCE
	VALAC_EXTRA_ARGS = -DPERSISTENCE --pkg persistence-1.0
endif

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(DBUS_CFLAGS) \
	$(GEE_CFLAGS) \
	$(PERSISTENCE_CFLAGS) \
	$(FSO_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_srcdir)/src/lib/libfsousage.la \
	$(DBUS_LIBS) \
	$(GEE_LIBS) \
	$(PERSISTENCE_LIBS) \
	$(FSO_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ./ \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsousage-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsousage
modlibexec_LTLIBRARIES = dbus_service.la
dbus_service_la_SOURCES = resource.c plugin.c
dbus_service_la_VALASOURCES = resource.vala plugin.vala
$(dbus_service_la_SOURCES): $(dbus_service_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $(VALAC_EXTRA_ARGS) $^
	touch $@
dbus_service_la_LIBADD = $(progs_ldadd)
dbus_service_la_LDFLAGS = -no-undefined -module -avoid-version
dbus_service_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    plugin.c \
    plugin.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
