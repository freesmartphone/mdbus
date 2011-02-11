include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.palmpre_quirks\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/src/lib \
	--pkg linux \
	--pkg uinput \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsodevice-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = palmpre_quirks.la
palmpre_quirks_la_VALASOURCES = \
	plugin.vala \
	touchscreenmanager.vala \
	powersupply.vala \
	powercontrol.vala \
	router.vala \
	$(NULL)
palmpre_quirks_la_SOURCES = $(palmpre_quirks_la_VALASOURCES:.vala=.c)
$(palmpre_quirks_la_SOURCES): $(palmpre_quirks_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
palmpre_quirks_la_LIBADD = $(progs_ldadd)
palmpre_quirks_la_LDFLAGS = -no-undefined -module -avoid-version
palmpre_quirks_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(palmpre_quirks_la_VALASOURCES) \
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

