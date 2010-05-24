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
	$(top_srcdir)/src/lib/libfsotdl.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotdl-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsotdl
modlibexec_LTLIBRARIES = location.la
location_la_SOURCES = plugin.c
location_la_VALASOURCES = plugin.vala
$(location_la_SOURCES): $(location_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
location_la_LIBADD = $(progs_ldadd)
location_la_LDFLAGS = -no-undefined -module -avoid-version
location_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
