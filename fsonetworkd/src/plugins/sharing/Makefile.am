NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_GLIB_LIBS) \
	$(FSO_LIBS) \
	$(DBUS_LIBS) \
	$(top_srcdir)/src/lib/libfsonetwork.la \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg dbus-glib-1 \
	--pkg fsoframework-2.0 \
	--pkg fso-glib-1.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsonetwork
modlibexec_LTLIBRARIES = sharing.la
sharing_la_SOURCES = plugin.c
sharing_la_VALASOURCES = plugin.vala
$(sharing_la_SOURCES): $(sharing_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
sharing_la_LIBADD = $(progs_ldadd)
sharing_la_LDFLAGS = -no-undefined -module -avoid-version
sharing_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    plugin.c \
    plugin.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
