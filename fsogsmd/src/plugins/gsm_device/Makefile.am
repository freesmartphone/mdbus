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
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg dbus-glib-1 \
	--pkg fsoframework-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = gsm_device.la
gsm_device_la_SOURCES = plugin.c plugin.h
gsm_device_la_VALASOURCES = plugin.vala
$(gsm_device_la_SOURCES): $(gsm_device_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
gsm_device_la_LIBADD = $(progs_ldadd)
gsm_device_la_LDFLAGS = -no-undefined -module -avoid-version
gsm_device_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
