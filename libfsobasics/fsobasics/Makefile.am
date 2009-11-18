include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(NULL)

BUILT_SOURCES = fsobasics.vala.stamp

lib_LTLIBRARIES = \
	libfsobasics.la
	$(NULL)

libfsobasics_la_VALASOURCES = \
	libinitexit.vala \
	logger.vala \
	smartkeyfile.vala \
	types.vala \
	utilities.vala \
	$(NULL)

libfsobasics_la_SOURCES = \
	fsobasics.vala.stamp \
	$(libfsobasics_la_VALASOURCES:.vala=.c) \
	gcc_libinitexit.c \
	$(NULL)

fsobasicsincludedir = $(includedir)/fsoframework-2.0
fsobasicsinclude_HEADERS = fsobasics.h

fsobasics-2.0.vapi fsobasics.vala.stamp: $(libfsobasics_la_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) \
	            --pkg posix \
	            --pkg linux \
	            --pkg glib-2.0 \
	            --pkg gio-2.0 \
	            --header fsobasics.h \
	            --library fsobasics-2.0 $^
	touch $@

libfsobasics_la_LIBADD = \
	$(GLIB_LIBS) \
	$(DBUS_LIBS) \
	$(ALSA_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsobasics-2.0.vapi \
	fsobasics-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsobasics_la_VALASOURCES) \
	fsobasics-2.0.vapi \
	fsobasics-2.0.deps \
	fsobasics.vala.stamp

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsobasics_la_VALASOURCES:.vala=.c) \
	$(NULL)


MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsobasics_la_VALASOURCES:.vala=.c) \
	Makefile.in \
	$(NULL)

