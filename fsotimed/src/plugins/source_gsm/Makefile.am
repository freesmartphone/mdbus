include $(top_srcdir)/Makefile.decl
NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(DBUS_LIBS) \
	$(top_srcdir)/src/lib/libfsotime.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsotime-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsotime
modlibexec_LTLIBRARIES = source_gsm.la
source_gsm_la_SOURCES = plugin.c
source_gsm_la_VALASOURCES = plugin.vala
$(source_gsm_la_SOURCES): $(source_gsm_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
source_gsm_la_LIBADD = $(progs_ldadd)
source_gsm_la_LDFLAGS = -no-undefined -module -avoid-version
source_gsm_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
