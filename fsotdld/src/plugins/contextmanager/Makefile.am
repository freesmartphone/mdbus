include $(top_srcdir)/Makefile.decl
NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsotdld.contextmanager\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsotdl.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gio-hacks \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotdl-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsotdl
modlibexec_LTLIBRARIES = contextmanager.la
contextmanager_la_SOURCES = plugin.c
contextmanager_la_VALASOURCES = plugin.vala
$(contextmanager_la_SOURCES): $(contextmanager_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
contextmanager_la_LIBADD = $(progs_ldadd)
contextmanager_la_LDFLAGS = -no-undefined -module -avoid-version
contextmanager_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(contextmanager_la_VALASOURCES) \
	$(contextmanager_la_SOURCES) \
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
