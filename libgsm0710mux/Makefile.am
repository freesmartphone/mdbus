NULL =

AUTOMAKE_OPTIONS = subdir-objects

VALAC_ARGS = \
	--vapidir ./vapi \
	--header gsm0710mux.h \
	--pkg config \
	--pkg gsm0710-1.0 \
	--pkg fsotransport-2.0 \
	--pkg fsobasics-2.0 \
	--library=gsm0710mux-1.0 \
	--save-temps --basedir $(top_srcdir)

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS = -ggdb -O0
endif

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = gsm0710mux-1.0.pc

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	gsm0710mux-1.0.vapi \
	gsm0710mux-1.0.deps \
	$(NULL)

SUBDIRS = \
	$(NULL)

INCLUDES = \
	$(DEPS_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

gsm0710muxincludedir = $(includedir)/gsm0710mux-1.0
gsm0710muxinclude_HEADERS = gsm0710mux.h

BUILT_SOURCES = gsm0710mux/.vala.stamp

lib_LTLIBRARIES = \
	libgsm0710mux.la \
	$(NULL)

libgsm0710mux_la_VALASOURCES = \
	gsm0710mux/consts.vala \
	gsm0710mux/channel.vala \
	gsm0710mux/multiplexer.vala \
	gsm0710mux/manager.vala \
	$(NULL)

libgsm0710mux_la_SOURCES = \
	$(libgsm0710mux_la_VALASOURCES:.vala=.c) \
	$(NULL)

gsm0710mux-1.0.vapi gsm0710mux/.vala.stamp: $(libgsm0710mux_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libgsm0710mux_la_LIBADD = \
	$(DEPS_LIBS) \
	$(NULL)

EXTRA_DIST = \
	MAINTAINERS \
	gsm0710mux-1.0.pc.in \
	gsm0710mux-1.0.vapi \
	gsm0710mux-1.0.deps \
	$(libgsm0710mux_la_VALASOURCES) \
	gsm0710mux/.vala.stamp \
	$(NULL)

CLEANFILES = \
	gsm0710mux/channel.? \
	gsm0710mux/serial.? \
	gsm0710mux/multiplexer.? \
	gsm0710mux/server.? \
	gsm0710mux/consts.? \
	gsm0710mux/main.? \
	gsm0710mux/.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

MAINTAINERCLEANFILES = aclocal.m4 compile config.guess config.sub \
                       configure depcomp install-sh ltmain.sh     \
                       Makefile.in missing config.h.in            \
                       intltool-extract \
                       intltool-merge \
                       intltool-update \
                       mkinstalldirs \
                       gsm0710mux/*.c gsm0710mux/*.h \
                       *~ \
                       gsm0710mux-1.0.gir \
                       gsm0710mux-1.0.vapi \
                       gsm0710mux-1.0.pc \
                       $(NULL)
