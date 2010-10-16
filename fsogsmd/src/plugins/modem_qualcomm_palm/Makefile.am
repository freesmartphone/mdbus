include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(PALM_CFLAGS) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(PALM_LIBS) \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(DBUS_LIBS) \
	$(top_srcdir)/src/lib/libfsogsm.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../../lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg dbus-glib-1 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogsm-2.0 \
	--pkg msmcommd-1.0 \
	$(NULL)

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsogsm
modlibexec_LTLIBRARIES = modem_qualcomm_palm.la

modem_qualcomm_palm_la_SOURCES = \
 channel.c \
 mediators.c \
 unsolicited.c \
 plugin.c \
 callhandler.c \
 data.c \
 phonebookhandler.c \
 consts.c \
 commandqueue.c \
 modemagent.c \
 mediators_debug.c \
 mediators_device.c \
 mediators_sim.c \
 mediators_sms.c \
 mediators_network.c \
 mediators_call.c \
 utils.c \
 $(NULL)
 
modem_qualcomm_palm_la_VALASOURCES = \
 channel.vala \
 mediators.vala \
 unsolicited.vala \
 plugin.vala \
 callhandler.vala \
 data.vala \
 phonebookhandler.vala \
 consts.vala \
 commandqueue.vala \
 modemagent.vala \
 mediators_debug.vala \
 mediators_device.vala \
 mediators_sim.vala \
 mediators_sms.vala \
 mediators_network.vala \
 mediators_call.vala \
 utils.vala \
 $(NULL)
 
$(modem_qualcomm_palm_la_SOURCES): $(modem_qualcomm_palm_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
modem_qualcomm_palm_la_LIBADD = $(progs_ldadd)
modem_qualcomm_palm_la_LDFLAGS = -no-undefined -module -avoid-version
modem_qualcomm_palm_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
