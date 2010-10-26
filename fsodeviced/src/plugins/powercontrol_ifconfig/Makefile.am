include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = powercontrol_ifconfig.la
powercontrol_ifconfig_la_SOURCES = plugin.c
powercontrol_ifconfig_la_VALASOURCES = plugin.vala
$(powercontrol_ifconfig_la_SOURCES): $(powercontrol_ifconfig_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
powercontrol_ifconfig_la_LIBADD = $(progs_ldadd)
powercontrol_ifconfig_la_LDFLAGS = -no-undefined -module -avoid-version
powercontrol_ifconfig_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
