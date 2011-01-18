include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(FSOBASICS_CFLAGS) \
	-D G_LOG_DOMAIN=\"fsoframework\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gmodule-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsobasics-2.0 \
	--pkg config \
	--header fsoframework.h \
	--library fsoframework-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = fsoframework.vala.stamp

lib_LTLIBRARIES = \
	libfsoframework.la
	$(NULL)

libfsoframework_la_VALASOURCES = \
	dbus.vala \
	interfaces.vala \
	object.vala \
	plugin.vala \
	resource.vala \
	subsystem.vala \
	$(NULL)

libfsoframework_la_SOURCES = \
	fsoframework.vala.stamp \
	$(libfsoframework_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsoframeworkincludedir = $(includedir)/fsoframework-2.0
fsoframeworkinclude_HEADERS = fsoframework.h

fsoframework-2.0.vapi fsoframework.vala.stamp: $(libfsoframework_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsoframework_la_LIBADD = \
	$(GLIB_LIBS) \
	$(FSOBASICS_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsoframework-2.0.vapi \
	fsoframework-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsoframework_la_VALASOURCES) \
	fsoframework-2.0.vapi \
	fsoframework-2.0.deps \
	fsoframework.vala.stamp

CLEANFILES = \
    $(BUILT_SOURCES) \
    $(libfsoframework_la_SOURCES) \
    $(NULL)


MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsoframework_la_SOURCES) \
	Makefile.in

