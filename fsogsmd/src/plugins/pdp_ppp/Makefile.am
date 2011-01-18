include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsogsm.pdp_ppp\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(top_srcdir)/src/lib/libfsogsm.la \
	$(FSO_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsogsm-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = pdp_ppp.la
pdp_ppp_la_SOURCES = plugin.c
pdp_ppp_la_VALASOURCES = plugin.vala
$(pdp_ppp_la_SOURCES): $(pdp_ppp_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
pdp_ppp_la_LIBADD = $(progs_ldadd)
pdp_ppp_la_LDFLAGS = -no-undefined -module -avoid-version
pdp_ppp_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    plugin.c \
    plugin.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
