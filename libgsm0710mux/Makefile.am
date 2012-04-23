NULL =

AUTOMAKE_OPTIONS = subdir-objects

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"gsm0710mux\" \
	-include $(CONFIG_HEADER) \
	$(NULL)
AM_VALAFLAGS =

if WANT_DEBUG
AM_CFLAGS += -ggdb -O0
endif

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = gsm0710mux-1.0.pc

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	gsm0710mux-1.0.vapi \
	gsm0710mux-1.0.deps \
	$(NULL)

gsm0710muxincludedir = $(includedir)/gsm0710mux-1.0
gsm0710muxinclude_HEADERS = gsm0710mux.h

lib_LTLIBRARIES = \
	libgsm0710mux.la \
	$(NULL)

libgsm0710mux_la_SOURCES = \
	gsm0710mux/consts.vala \
	gsm0710mux/channel.vala \
	gsm0710mux/multiplexer.vala \
	gsm0710mux/manager.vala \
	$(NULL)
libgsm0710mux_la_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	--vapidir ./vapi \
	--header gsm0710mux.h \
	--pkg config \
	--pkg gsm0710-1.0 \
	--pkg fsotransport-2.0 \
	--pkg fsobasics-2.0 \
	--library=gsm0710mux-1.0 \
	--save-temps --basedir $(top_srcdir) \
	$(NULL)
libgsm0710mux_la_CFLAGS = $(DEPS_CFLAGS)
libgsm0710mux_la_LIBADD = \
	$(DEPS_LIBS) \
	$(NULL)

EXTRA_DIST = \
	MAINTAINERS \
	gsm0710mux-1.0.pc.in \
	$(NULL)

BUILT_SOURCES = \
	gsm0710mux.h \
	gsm0710mux-1.0.vapi \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)
