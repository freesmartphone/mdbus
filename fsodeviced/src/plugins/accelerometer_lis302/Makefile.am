include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.accelerometer_lis302\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(GLIB_LIBS) \
	$(FSO_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ./ \
	--vapidir $(top_srcdir)/src/lib \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsodevice-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = accelerometer_lis302.la
accelerometer_lis302_la_SOURCES = plugin.c
accelerometer_lis302_la_VALASOURCES = plugin.vala
$(accelerometer_lis302_la_SOURCES): $(accelerometer_lis302_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
accelerometer_lis302_la_LIBADD = $(progs_ldadd)
accelerometer_lis302_la_LDFLAGS = -no-undefined -module -avoid-version
accelerometer_lis302_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(accelerometer_lis302_la_VALASOURCES) \
	$(accelerometer_lis302_la_SOURCES) \
	$(NULL)

CLEANFILES = \
    plugin.c \
    plugin.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
