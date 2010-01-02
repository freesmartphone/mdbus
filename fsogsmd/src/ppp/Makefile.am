include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(DBUS_LIBS) \
	$(top_srcdir)/src/lib/libfsogsm.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg ppp \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsobasics-2.0

#
# plugin
#
modlibexecdir = $(PPPD_PLUGIN_DIR)
modlibexec_LTLIBRARIES = fsogsmd.la
fsogsmd_la_SOURCES = plugin.c
fsogsmd_la_VALASOURCES = plugin.vala
$(fsogsmd_la_SOURCES): $(fsogsmd_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
fsogsmd_la_LIBADD = $(progs_ldadd)
fsogsmd_la_LDFLAGS = -no-undefined -module -avoid-version
fsogsmd_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
