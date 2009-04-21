include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
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
	--pkg gsm0710mux-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
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
	$(libfsogsm_la_VALASOURCES:.vala=.h) \
	$(NULL)

fsogsmincludedir = $(includedir)/fsoframework-2.0/fsogsm

fsogsminclude_HEADERS = \
	$(libfsogsm_la_VALASOURCES:.vala=.h) \
	$(NULL)

$(BUILT_SOURCES): $(libfsogsm_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsogsm_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GSMMUX_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsogsm-2.0.vapi \
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

