include $(top_srcdir)/Makefile.decl

NULL =

# third party
THIRDPARTY_SOURCES = \
	$(top_srcdir)/src/3rdparty/conversions.c \
	$(top_srcdir)/src/3rdparty/smsutil.c \
	$(top_srcdir)/src/3rdparty/storage.c \
	$(top_srcdir)/src/3rdparty/util.c \
	$(NULL)
	
AM_CFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/src/3rdparty \
	-Ifoo/bar \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(GSMMUX_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	-D DEBUG \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/3rdparty \
	--pkg posix \
	--pkg posixextra \
	--pkg dbus-glib-1 \
	--pkg glib-2.0 \
	--pkg fsogsm3rdparty \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg gsm0710mux-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--header fsogsm.h \
	--library fsogsm-2.0

BUILT_SOURCES = .vala.stamp fsogsm-2.0.vapi

lib_LTLIBRARIES = \
	libfsogsm.la
	$(NULL)

libfsogsm_la_VALASOURCES = \
	atcall.vala \
	atcommand.vala \
	atcommands.vala \
	atmediators.vala \
	atparser.vala \
	atunsolicited.vala \
	codes.vala \
	consts.vala \
	channel.vala \
	mediator.vala \
	modem.vala \
	structs.vala \
	transport.vala \
	$(NULL)

libfsogsm_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsogsm_la_VALASOURCES:.vala=.c) \
	$(THIRDPARTY_SOURCES) \
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
	$(THIRDPARTY_LIBS) \
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
        $(libfsogsm_la_VALASOURCES:.vala=.c) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(CLEANFILES) \
	Makefile.in

