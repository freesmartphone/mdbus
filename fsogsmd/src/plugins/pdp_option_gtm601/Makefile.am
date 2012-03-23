include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsogsm.pdp_option_gtm601\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_builddir)/src/lib/libfsogsm.la \
	$(FSO_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--thread \
	--pkg thread \
	--pkg glib-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsogsm-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = pdp_option_gtm601.la
pdp_option_gtm601_la_SOURCES = plugin.c 
pdp_option_gtm601_la_VALASOURCES = plugin.vala
$(pdp_option_gtm601_la_SOURCES): $(pdp_option_gtm601_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
pdp_option_gtm601_la_LIBADD = $(progs_ldadd)
pdp_option_gtm601_la_LDFLAGS = -no-undefined -module -avoid-version
pdp_option_gtm601_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(pdp_option_gtm601_la_VALASOURCES) \
	$(pdp_option_gtm601_la_SOURCES) \
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
