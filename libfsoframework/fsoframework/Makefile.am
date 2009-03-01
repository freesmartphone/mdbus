include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(DEPS_CFLAGS) \
	$(NULL)

BUILT_SOURCES = fsoframework.vala.stamp

lib_LTLIBRARIES = \
	libfsoframework.la
	$(NULL)

libfsoframework_la_VALASOURCES = \
	common.vala \
	logger.vala \
	smartkeyfile.vala \
	$(NULL)

libfsoframework_la_SOURCES = \
	fsoframework.vala.stamp \
	$(libfsoframework_la_VALASOURCES:.vala=.c) \
	$(libfsoframework_la_VALASOURCES:.vala=.h) \
	$(NULL)

fsoframeworkincludedir = $(includedir)/fsoframework-2.0/fsoframework

fsoframeworkinclude_HEADERS = \
	$(libfsoframework_la_VALASOURCES:.vala=.h) \
	$(NULL)

fsoframework-1.0.vapi fsoframework.vala.stamp: $(libfsoframework_la_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) \
	            --vapidir ../vapi \
	            --pkg posix \
	            --pkg posixextra \
	            --pkg glib-2.0 \
	            --pkg gio-2.0 \
	            --library fsoframework-2.0 $^
	touch $@

libfsoframework_la_LIBADD = \
	$(DEPS_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsoframework-2.0.vapi \
	$(NULL)

EXTRA_DIST += \
	$(libfsoframework_la_VALASOURCES) \
	fsoframework-2.0.vapi \
	fsoframework.vala.stamp

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsoframework_la_SOURCES) \
	Makefile.in

