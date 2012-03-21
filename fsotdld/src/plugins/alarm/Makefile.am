include $(top_srcdir)/Makefile.decl
NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsotdld.alarm\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsotdl.la \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsotdl
modlibexec_LTLIBRARIES = alarm.la
alarm_la_SOURCES = plugin.c
alarm_la_VALASOURCES = plugin.vala
$(alarm_la_SOURCES): $(alarm_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
alarm_la_LIBADD = $(progs_ldadd)
alarm_la_LDFLAGS = -no-undefined -module -avoid-version
alarm_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(alarm_la_VALASOURCES) \
	$(alarm_la_SOURCES) \
	$(NULL)

CLEANFILES = \
	*.h \
	$(alarm_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
