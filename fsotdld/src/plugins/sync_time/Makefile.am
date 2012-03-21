include $(top_srcdir)/Makefile.decl
NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsotdld.sync_time\" \
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
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotdl-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsotdl
modlibexec_LTLIBRARIES = sync_time.la
sync_time_la_SOURCES = plugin.c
sync_time_la_VALASOURCES = plugin.vala
$(sync_time_la_SOURCES): $(sync_time_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
sync_time_la_LIBADD = $(progs_ldadd)
sync_time_la_LDFLAGS = -no-undefined -module -avoid-version
sync_time_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(sync_time_la_VALASOURCES) \
	$(sync_time_la_SOURCES) \
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
