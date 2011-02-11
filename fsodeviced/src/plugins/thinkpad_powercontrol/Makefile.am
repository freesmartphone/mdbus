include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.thinkpad_powercontrol\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg glib-2.0 \
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
modlibexec_LTLIBRARIES = thinkpad_powercontrol.la
thinkpad_powercontrol_la_SOURCES = plugin.c
thinkpad_powercontrol_la_VALASOURCES = plugin.vala
$(thinkpad_powercontrol_la_SOURCES): $(thinkpad_powercontrol_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
thinkpad_powercontrol_la_LIBADD = $(progs_ldadd)
thinkpad_powercontrol_la_LDFLAGS = -no-undefined -module -avoid-version
thinkpad_powercontrol_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(thinkpad_powercontrol_la_VALASOURCES) \
	$(NULL)

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
