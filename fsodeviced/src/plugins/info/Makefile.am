NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(FSO_LIBS) $(DBUS_LIBS) $(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg dbus-glib-1 \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0 \
	--pkg posix



#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = info.la
info_la_SOURCES = plugin.c plugin.h
info_la_VALASOURCES = plugin.vala
$(info_la_SOURCES): $(info_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
info_la_LIBADD = $(progs_ldadd)
info_la_LDFLAGS = -no-undefined -module -avoid-version
info_la_LIBTOOLFLAGS = --tag=disable-static00

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
