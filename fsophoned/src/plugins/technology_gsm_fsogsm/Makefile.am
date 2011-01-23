include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_srcdir)/src/lib/libfsophone.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsophone-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsophone
modlibexec_LTLIBRARIES = technology_gsm_fsogsm.la
technology_gsm_fsogsm_la_SOURCES = plugin.c
technology_gsm_fsogsm_la_VALASOURCES = plugin.vala
$(technology_gsm_fsogsm_la_SOURCES): $(technology_gsm_fsogsm_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
technology_gsm_fsogsm_la_LIBADD = $(progs_ldadd)
technology_gsm_fsogsm_la_LDFLAGS = -no-undefined -module -avoid-version
technology_gsm_fsogsm_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
