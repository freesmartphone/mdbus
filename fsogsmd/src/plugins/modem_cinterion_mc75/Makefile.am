include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsogsm.modem_cinterion_mc75\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsogsm.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_builddir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg gsm0710mux-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogsm-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = modem_cinterion_mc75.la
modem_cinterion_mc75_la_SOURCES = commands.c unsolicited.c plugin.c
modem_cinterion_mc75_la_VALASOURCES = commands.vala unsolicited.vala plugin.vala
$(modem_cinterion_mc75_la_SOURCES): $(modem_cinterion_mc75_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
modem_cinterion_mc75_la_LIBADD = $(progs_ldadd)
modem_cinterion_mc75_la_LDFLAGS = -no-undefined -module -avoid-version
modem_cinterion_mc75_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(modem_cinterion_mc75_la_VALASOURCES) \
	$(modem_cinterion_mc75_la_SOURCES) \
	$(NULL)

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
