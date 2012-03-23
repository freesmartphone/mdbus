include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(SAMSUNG_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsogsm.lowlevel_samsung_crespo\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_builddir)/src/lib/libfsogsm.la \
	$(FSO_LIBS) \
	$(SAMSUNG_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsogsm-2.0 \
	--pkg samsung-ipc-1.0 \
	$(NULL)

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = lowlevel_samsung_crespo.la
lowlevel_samsung_crespo_la_SOURCES = plugin.c
lowlevel_samsung_crespo_la_VALASOURCES = plugin.vala
$(lowlevel_samsung_crespo_la_SOURCES): $(lowlevel_samsung_crespo_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
lowlevel_samsung_crespo_la_LIBADD = $(progs_ldadd)
lowlevel_samsung_crespo_la_LDFLAGS = -no-undefined -module -avoid-version
lowlevel_samsung_crespo_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(lowlevel_samsung_crespo_la_VALASOURCES) \
	$(lowlevel_samsung_crespo_la_SOURCES) \
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
