NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(FSO_LIBS) $(DBUS_LIBS) $(top_srcdir)/src/lib/libfsousage.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ./ \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg controller \
	--pkg glib-2.0 \
	--pkg dbus-glib-1 \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsousage
modlibexec_LTLIBRARIES = controller.la
controller_la_SOURCES = plugin.c
controller_la_VALASOURCES = plugin.vala
$(controller_la_SOURCES): $(controller_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
controller_la_LIBADD = $(progs_ldadd)
controller_la_LDFLAGS = -no-undefined -module -avoid-version
controller_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    plugin.c \
    plugin.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
