include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"gsm0710mux\" \
	-include $(CONFIG_HEADER) \
	$(NULL)
AM_VALAFLAGS =


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
	consts.vala \
	channel.vala \
	multiplexer.vala \
	manager.vala \
	$(NULL)
libgsm0710mux_la_VALAFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/fsobasics \
	--vapidir $(top_srcdir)/fsotransport \
	--header gsm0710mux.h \
	--pkg config \
	--pkg gsm0710-1.0 \
	--pkg fsotransport-2.0 \
	--pkg fsobasics-2.0 \
	--library=gsm0710mux-1.0 \
	--save-temps \
	--basedir $(top_srcdir) \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
libgsm0710mux_la_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(GSM0710_CFLAGS) \
	$(LIBNL_CFLAGS) \
	-I$(top_srcdir)/fsobasics \
	-I$(top_srcdir)/fsotransport \
	$(NULL)
libgsm0710mux_la_LIBADD = \
	$(GLIB_LIBS) \
	$(GSM0710_LIBS) \
	$(top_builddir)/fsobasics/libfsobasics.la \
	$(top_builddir)/fsotransport/libfsotransport.la \
	$(NULL)
libgsm0710mux_la_LDFLAGS = \
	$(AM_LDFLAGS) \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	$(NULL)


EXTRA_DIST += \
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
