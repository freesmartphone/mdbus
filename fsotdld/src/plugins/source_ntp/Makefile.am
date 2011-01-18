include $(top_srcdir)/Makefile.decl
NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsotdld.source_ntp\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_srcdir)/src/lib/libfsotdl.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsotdl-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsotdl
modlibexec_LTLIBRARIES = source_ntp.la
source_ntp_la_SOURCES = plugin.c
source_ntp_la_VALASOURCES = plugin.vala
$(source_ntp_la_SOURCES): $(source_ntp_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
source_ntp_la_LIBADD = $(progs_ldadd)
source_ntp_la_LDFLAGS = -no-undefined -module -avoid-version
source_ntp_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
