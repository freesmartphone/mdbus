include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg dbus-glib-1 \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--header fsolocation.h \
	--library fsolocation-2.0

BUILT_SOURCES = .vala.stamp fsolocation-2.0.vapi

lib_LTLIBRARIES = \
	libfsolocation.la
	$(NULL)

libfsolocation_la_VALASOURCES = \
	channel.vala \
	receiver.vala \
	$(NULL)

libfsolocation_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsolocation_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsolocationincludedir = $(includedir)/fsoframework-2.0
fsolocationinclude_HEADERS = fsolocation.h

$(BUILT_SOURCES): $(libfsolocation_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsolocation_la_LIBADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsolocation-2.0.vapi \
	fsolocation-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsolocation_la_VALASOURCES) \
	$(BUILT_SOURCES)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsolocation_la_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsolocation_la_SOURCES) \
	Makefile.in

