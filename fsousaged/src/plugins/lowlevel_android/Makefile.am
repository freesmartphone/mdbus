include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GEE_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsousage.lowlevel_android\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_srcdir)/src/lib/libfsousage.la \
	$(GEE_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ./ \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsousage-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsousage
modlibexec_LTLIBRARIES = lowlevel_android.la
lowlevel_android_la_SOURCES = plugin.c
lowlevel_android_la_VALASOURCES = plugin.vala
$(lowlevel_android_la_SOURCES): $(lowlevel_android_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
lowlevel_android_la_LIBADD = $(progs_ldadd)
lowlevel_android_la_LDFLAGS = -no-undefined -module -avoid-version
lowlevel_android_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    plugin.c \
    plugin.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
