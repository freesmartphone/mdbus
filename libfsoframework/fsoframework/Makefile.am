include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(ALSA_CFLAGS) \
	$(FSOBASICS_CFLAGS) \
	$(NULL)

BUILT_SOURCES = fsoframework.vala.stamp

lib_LTLIBRARIES = \
	libfsoframework.la
	$(NULL)

libfsoframework_la_VALASOURCES = \
	alsa.vala \
	asyncworker.vala \
	common.vala \
	dbus.vala \
	interfaces.vala \
	kobjectnotifier.vala \
	object.vala \
	plugin.vala \
	subsystem.vala \
	$(NULL)

libfsoframework_la_SOURCES = \
	fsoframework.vala.stamp \
	$(libfsoframework_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsoframeworkincludedir = $(includedir)/fsoframework-2.0
fsoframeworkinclude_HEADERS = fsoframework.h

fsoframework-1.0.vapi fsoframework.vala.stamp: $(libfsoframework_la_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) \
	            --vapidir ../vapi \
	            --pkg posix \
	            --pkg posixextra \
	            --pkg linux26 \
	            --pkg glib-2.0 \
	            --pkg gmodule-2.0 \
	            --pkg gio-2.0 \
	            --pkg dbus-glib-1 \
	            --pkg libasound \
	            --pkg fsobasics-2.0 \
	            --header fsoframework.h \
	            --library fsoframework-2.0 $^
	touch $@

libfsoframework_la_LIBADD = \
	$(GLIB_LIBS) \
	$(DBUS_LIBS) \
	$(ALSA_LIBS) \
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

