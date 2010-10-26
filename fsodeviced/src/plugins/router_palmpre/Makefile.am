include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_srcdir)/src/lib/libfsodevice.la \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir . \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = router_palmpre.la
router_palmpre_la_SOURCES = plugin.c
router_palmpre_la_VALASOURCES = plugin.vala
$(router_palmpre_la_SOURCES): $(router_palmpre_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
router_palmpre_la_LIBADD = $(progs_ldadd)
router_palmpre_la_LDFLAGS = -no-undefined -module -avoid-version
router_palmpre_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    plugin.c \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
