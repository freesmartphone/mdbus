include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.router_alsa\" \
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
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = router_alsa.la
router_alsa_la_SOURCES = plugin.c
router_alsa_la_VALASOURCES = plugin.vala
$(router_alsa_la_SOURCES): $(router_alsa_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
router_alsa_la_LIBADD = $(progs_ldadd)
router_alsa_la_LDFLAGS = -no-undefined -module -avoid-version
router_alsa_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(router_alsa_la_VALASOURCES) \
	$(NULL)

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
