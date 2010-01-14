include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_srcdir)/src/lib/libfsodevice.la \
	$(FSO_LIBS) \
	$(DBUS_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir . \
	--pkg playwav2 \
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
modlibexec_LTLIBRARIES = router_qdsp5.la
router_qdsp5_la_SOURCES = plugin.c playwav2.c
router_qdsp5_la_VALASOURCES = plugin.vala
$(router_qdsp5_la_SOURCES): $(router_qdsp5_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
router_qdsp5_la_LIBADD = $(progs_ldadd)
router_qdsp5_la_LDFLAGS = -no-undefined -module -avoid-version
router_qdsp5_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    $(router_qdsp5_la_SOURCES) \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
