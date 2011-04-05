include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(CONNMAN_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsogsm.connman\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(CONNMAN_LIBS) \
	$(top_srcdir)/src/lib/libfsogsm.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg connman \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	$(NULL)

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CPPFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/connman/plugins
modlibexec_LTLIBRARIES = fsogsm.la
fsogsm_la_SOURCES = connman-wrapper.c plugin.c modemhandler.c
fsogsm_la_VALASOURCES = plugin.vala modemhandler.vala
$(fsogsm_la_SOURCES): $(fsogsm_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
fsogsm_la_LIBADD = $(progs_ldadd)
fsogsm_la_LDFLAGS = -no-undefined -module -avoid-version
fsogsm_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    $(fsogsm_la_VALASOURCES:.vala=.c) \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
