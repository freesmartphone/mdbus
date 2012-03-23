include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsogsm.modem_qualcomm_htc\" \
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
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogsm-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = modem_qualcomm_htc.la
# warning: file order is important here! otherwise we run into vala bug https://bugzilla.gnome.org/show_bug.cgi?id=553928
modem_qualcomm_htc_la_SOURCES = htcparser.c commands.c unsolicited.c plugin.c
modem_qualcomm_htc_la_VALASOURCES = htcparser.vala commands.vala unsolicited.vala plugin.vala
$(modem_qualcomm_htc_la_SOURCES): $(modem_qualcomm_htc_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
modem_qualcomm_htc_la_LIBADD = $(progs_ldadd)
modem_qualcomm_htc_la_LDFLAGS = -no-undefined -module -avoid-version
modem_qualcomm_htc_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(modem_qualcomm_htc_la_VALASOURCES) \
	$(modem_qualcomm_htc_la_SOURCES) \
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
