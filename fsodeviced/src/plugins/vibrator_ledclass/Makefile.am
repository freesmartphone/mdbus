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
modlibexec_LTLIBRARIES = vibrator_ledclass.la
vibrator_ledclass_la_SOURCES = plugin.c
vibrator_ledclass_la_VALASOURCES = plugin.vala
$(vibrator_ledclass_la_SOURCES): $(vibrator_ledclass_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
vibrator_ledclass_la_LIBADD = $(progs_ldadd)
vibrator_ledclass_la_LDFLAGS = -no-undefined -module -avoid-version
vibrator_ledclass_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
