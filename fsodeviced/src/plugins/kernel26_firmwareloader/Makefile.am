include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(DBUS_LIBS) \
	$(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0

if WANT_FSORESOURCE
VALAC_ARGS += -D WANT_FSO_RESOURCE
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = kernel26_firmwareloader.la
kernel26_firmwareloader_la_SOURCES = plugin.c
kernel26_firmwareloader_la_VALASOURCES = plugin.vala
$(kernel26_firmwareloader_la_SOURCES): $(kernel26_firmwareloader_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
kernel26_firmwareloader_la_LIBADD = $(progs_ldadd)
kernel26_firmwareloader_la_LDFLAGS = -no-undefined -module -avoid-version
kernel26_firmwareloader_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
