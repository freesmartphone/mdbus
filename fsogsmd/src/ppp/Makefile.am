include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsogsm.ppp\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsogsm.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg ppp \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	$(NULL)

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = ppp2fsogsmd.la
ppp2fsogsmd_la_SOURCES = plugin.c
ppp2fsogsmd_la_VALASOURCES = plugin.vala
$(ppp2fsogsmd_la_SOURCES): $(ppp2fsogsmd_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
ppp2fsogsmd_la_LIBADD = $(progs_ldadd)
ppp2fsogsmd_la_LDFLAGS = -no-undefined -module -avoid-version
ppp2fsogsmd_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(ppp2fsogsmd_la_VALASOURCES) \
	$(ppp2fsogsmd_la_SOURCES) \
	pppd-local.h \
	$(NULL)

CLEANFILES = \
    *.c \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
