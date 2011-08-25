include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	$(FSO_GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-I$(top_srcdir)/src/lib
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_srcdir)/src/lib/libfsoapp.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsoapp-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsoapp
modlibexec_LTLIBRARIES = controller_e17.la
controller_e17_la_SOURCES = plugin.c
controller_e17_la_VALASOURCES = plugin.vala
$(controller_e17_la_SOURCES): $(controller_e17_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
controller_e17_la_LIBADD = $(progs_ldadd)
controller_e17_la_LDFLAGS = -no-undefined -module -avoid-version
controller_e17_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
