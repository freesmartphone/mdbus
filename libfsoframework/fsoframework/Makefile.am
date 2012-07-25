include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(FSOBASICS_CFLAGS) \
	-D G_LOG_DOMAIN=\"fsoframework\" \
	$(NULL)

AM_VALAFLAGS = \
	$(NULL)


lib_LTLIBRARIES = libfsoframework.la

libfsoframework_la_SOURCES = \
	dbus.vala \
	interfaces.vala \
	plugin.vala \
	resource.vala \
	subsystem.vala \
	$(NULL)

libfsoframework_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gmodule-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsobasics-2.0 \
	--pkg config \
	--header fsoframework.h \
	--library fsoframework-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)

libfsoframework_la_LIBADD = \
	$(GLIB_LIBS) \
	$(FSOBASICS_LIBS) \
	$(NULL)
libfsoframework_la_LDFLAGS = \
	$(AM_LDFLAGS) \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	$(NULL)

fsoframeworkincludedir = $(includedir)/fsoframework-2.0
fsoframeworkinclude_HEADERS = fsoframework.h

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	fsoframework-2.0.vapi \
	fsoframework-2.0.deps \
	$(NULL)

BUILT_SOURCES = \
	fsoframework.h \
	fsoframework-2.0.vapi \
	$(NULL)

EXTRA_DIST += \
	fsoframework-2.0.pc.in \
	$(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = fsoframework-2.0.pc

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)
