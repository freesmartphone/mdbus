include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(FSO_LIBS) $(DBUS_LIBS) $(top_srcdir)/src/lib/libfsogsm.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg dbus-glib-1 \
	--pkg fsoframework-2.0 \
	--pkg fsogsm-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = modem_cinterion_mc75.la
modem_cinterion_mc75_la_SOURCES = plugin.c plugin.h
modem_cinterion_mc75_la_VALASOURCES = plugin.vala
$(modem_cinterion_mc75_la_SOURCES): $(modem_cinterion_mc75_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
modem_cinterion_mc75_la_LIBADD = $(progs_ldadd)
modem_cinterion_mc75_la_LDFLAGS = -no-undefined -module -avoid-version
modem_cinterion_mc75_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
