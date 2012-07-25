include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsotransport\" \
	-I$(top_srcdir) \
	-I$(top_srcdir)/fsobasics \
	$(LIBNL_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

AM_VALAFLAGS = \
	$(NULL)


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
	--vapidir $(top_srcdir)/fsobasics \
	--pkg posix \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsobasics-2.0 \
	--header fsotransport.h \
	--library fsotransport-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)

if WANT_NGSM
AM_CFLAGS += -I$(top_srcdir)/3rdparty
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

EXTRA_DIST += \
	fsotransport-2.0.pc.in \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = fsotransport-2.0.pc

BUILT_SOURCES = \
	fsotransport.h \
	fsotransport-2.0.vapi \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)
