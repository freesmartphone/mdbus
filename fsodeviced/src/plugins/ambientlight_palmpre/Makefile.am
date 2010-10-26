include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(top_srcdir)/src/lib/libfsodevice.la \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = ambientlight_palmpre.la
ambientlight_palmpre_la_SOURCES = plugin.c
ambientlight_palmpre_la_VALASOURCES = plugin.vala
$(ambientlight_palmpre_la_SOURCES): $(ambientlight_palmpre_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
ambientlight_palmpre_la_LIBADD = $(progs_ldadd)
ambientlight_palmpre_la_LDFLAGS = -no-undefined -module -avoid-version
ambientlight_palmpre_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
