include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GSTREAMER_CFLAGS) \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_srcdir)/src/lib/libfsodevice.la \
	$(GSTREAMER_LIBS) \
	$(FSO_LIBS) \
	$(DBUS_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--thread \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg thread \
	--pkg gstreamer-0.10 \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0
#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = player_gstreamer.la
player_gstreamer_la_SOURCES = plugin.c
player_gstreamer_la_VALASOURCES = plugin.vala
$(player_gstreamer_la_SOURCES): $(player_gstreamer_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
player_gstreamer_la_LIBADD = $(progs_ldadd)
player_gstreamer_la_LDFLAGS = -no-undefined -module -avoid-version
player_gstreamer_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
