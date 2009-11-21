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
	$(top_srcdir)/src/lib/libfsodata.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotime-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodata
modlibexec_LTLIBRARIES = world.la
world_la_SOURCES = plugin.c
world_la_VALASOURCES = plugin.vala
$(world_la_SOURCES): $(world_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
world_la_LIBADD = $(progs_ldadd)
world_la_LDFLAGS = -no-undefined -module -avoid-version
world_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
