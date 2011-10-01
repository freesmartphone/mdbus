include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsobasics-2.0 \
	--header fsotransport.h \
	--library fsotransport-2.0

AM_CFLAGS = -DG_LOG_DOMAIN=\"fsotransport\"

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

if FAST_BAUD
VALAC_ARGS += -D FAST_BAUD
endif

BUILT_SOURCES = .vala.stamp

lib_LTLIBRARIES = \
	libfsotransport.la
	$(NULL)

libfsotransport_la_VALASOURCES = \
	basetransport.vala \
	commandqueue.vala \
	delegate.vala \
	null.vala \
	parser.vala \
	pipe.vala \
	pty.vala \
	serial.vala \
	socket.vala \
	transport.vala \
	raw.vala \
	$(NULL)

if WANT_PALMPRE_HSUART
VALAC_ARGS += --pkg hsuart
AM_CPPFLAGS += -I$(top_srcdir)/3rdparty
libfsotransport_la_VALASOURCES += hsuart.vala
endif

if WANT_NGSM
AM_CPPFLAGS += -I$(top_srcdir)/linux
libfsotransport_la_VALASOURCES += ngsm.vala
endif

if WANT_CRESPO_MODEM_CONTROL
VALAC_ARGS += --pkg crespo-modem-ctl
AM_CPPFLAGS += -I$(top_srcdir)/3rdparty
libfsotransport_la_VALASOURCES += crespo.vala
endif

libfsotransport_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsotransport_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsotransportincludedir = $(includedir)/fsoframework-2.0

fsotransportinclude_HEADERS = fsotransport.h

fsotransport-2.0.vapi .vala.stamp: $(libfsotransport_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsotransport_la_LIBADD = \
	$(GLIB_LIBS) \
	-lutil \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsotransport-2.0.vapi \
	fsotransport-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsotransport_la_VALASOURCES) \
	fsotransport-2.0.vapi \
	$(BUILT_SOURCES) \
	$(NULL)

CLEANFILES = \
    $(BUILT_SOURCES) \
    $(libfsotransport_la_SOURCES) \
    $(NULL)

MAINTAINERCLEANFILES = \
	$(CLEANFILES) \
	Makefile.in
