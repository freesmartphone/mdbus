include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.proximity_n900\" \
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
	--pkg fsoresource-2.0 \
	--pkg fsoframework-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = proximity_n900.la
proximity_n900_la_SOURCES = plugin.c
proximity_n900_la_VALASOURCES = plugin.vala
$(proximity_n900_la_SOURCES): $(proximity_n900_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
proximity_n900_la_LIBADD = $(progs_ldadd)
proximity_n900_la_LDFLAGS = -no-undefined -module -avoid-version
proximity_n900_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
