include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GSMMUX_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg posixextra \
	--pkg dbus-glib-1 \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg gsm0710mux-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--header fsogsm.h \
	--library fsogsm-2.0

BUILT_SOURCES = .vala.stamp fsogsm-2.0.vapi

lib_LTLIBRARIES = \
	libfsogsm.la
	$(NULL)

libfsogsm_la_VALASOURCES = \
	atcommand.vala \
	atcommands.vala \
	commandqueue.vala \
	channel.vala \
	mediator.vala \
	mediators.vala \
	modem.vala \
	parser.vala \
	transport.vala \
	$(NULL)

libfsogsm_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsogsm_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsogsmincludedir = $(includedir)/fsoframework-2.0
fsogsminclude_HEADERS = fsogsm.h

$(BUILT_SOURCES): $(libfsogsm_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsogsm_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(GSMMUX_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsogsm-2.0.vapi \
	fsogsm-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsogsm_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsogsm_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsogsm_la_SOURCES) \
	Makefile.in

