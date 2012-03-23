include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsoaudio.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsoaudio-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsoaudio
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
	$(router_alsa_la_SOURCES) \
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
