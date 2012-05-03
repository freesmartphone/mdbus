include $(top_srcdir)/Makefile.decl
NULL =

AM_CPPFLAGS = \
	-DG_LOG_DOMAIN=\"fsotransport\" \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(NULL)

AM_VALAFLAGS = \
	$(NULL)

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CPPFLAGS += -g -ggdb
endif

if FAST_BAUD
AM_VALAFLAGS += -D FAST_BAUD
endif

lib_LTLIBRARIES = libfsotransport.la

libfsotransport_la_SOURCES = \
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
	combined.vala \
	$(NULL)

libfsotransport_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsobasics-2.0 \
	--header fsotransport.h \
	--library fsotransport-2.0 \
	$(NULL)

if WANT_PALMPRE_HSUART
libfsotransport_la_VALAFLAGS += --pkg hsuart
AM_CPPFLAGS += -I$(top_srcdir)/3rdparty
libfsotransport_la_SOURCES += hsuart.vala
endif

if WANT_NGSM
AM_CPPFLAGS += -I$(top_srcdir)/3rdparty
libfsotransport_la_SOURCES += ngsm.vala
endif

libfsotransport_la_LIBADD = \
	$(GLIB_LIBS) \
	-lutil \
	$(NULL)
libfsotransport_la_LDFLAGS = \
	$(AM_LDFLAGS) \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	$(NULL)

fsotransportincludedir = $(includedir)/fsoframework-2.0
fsotransportinclude_HEADERS = fsotransport.h

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	fsotransport-2.0.vapi \
	fsotransport-2.0.deps \
	$(NULL)

BUILT_SOURCES = \
	fsotransport.h \
	fsotransport-2.0.vapi \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)
