include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.player_alsa\" \
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
modlibexec_LTLIBRARIES = player_alsa.la
player_alsa_la_SOURCES = plugin.c
player_alsa_la_VALASOURCES = plugin.vala
$(player_alsa_la_SOURCES): $(player_alsa_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
player_alsa_la_LIBADD = $(progs_ldadd)
player_alsa_la_LDFLAGS = -no-undefined -module -avoid-version
player_alsa_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
