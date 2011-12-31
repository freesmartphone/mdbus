include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.herring_quirks\" \
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
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsosystem-2.0 \
	--pkg fsodevice-2.0

if WANT_FSORESOURCE
VALAC_ARGS += -D WANT_FSO_RESOURCE
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = herring_quirks.la
herring_quirks_la_VALASOURCES = \
	plugin.vala \
	resumehandler.vala \
	alsa.vala \
	$(NULL)
herring_quirks_la_SOURCES = $(herring_quirks_la_VALASOURCES:.vala=.c)
$(herring_quirks_la_SOURCES): $(herring_quirks_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
herring_quirks_la_LIBADD = $(progs_ldadd)
herring_quirks_la_LDFLAGS = -no-undefined -module -avoid-version
herring_quirks_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(herring_quirks_la_VALASOURCES) \
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

