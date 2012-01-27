include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg linuxext \
	--header fsosystem.h \
	--library fsosystem-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = fsosystem.vala.stamp

lib_LTLIBRARIES = \
	libfsosystem.la
	$(NULL)

libfsosystem_la_VALASOURCES = \
	modules.vala \
	network.vala \
	filesystem.vala \
	path.vala \
	wakelock.vala \
	$(NULL)

libfsosystem_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libfsosystem_la_VALASOURCES:.vala=.c) \
	$(NULL)

fsosystemincludedir = $(includedir)/fsoframework-2.0
fsosysteminclude_HEADERS = fsosystem.h

fsosystem-2.0.vapi fsosystem.vala.stamp: $(libfsosystem_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsosystem_la_LIBADD = \
	$(GLIB_LIBS) \
	$(LIBNL_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsosystem-2.0.vapi \
	fsosystem-2.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libfsosystem_la_VALASOURCES) \
	fsosystem-2.0.vapi \
	fsosystem-2.0.deps \
	fsosystem.vala.stamp

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsosystem_la_VALASOURCES:.vala=.c) \
	$(NULL)


MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libfsosystem_la_VALASOURCES:.vala=.c) \
	Makefile.in \
	$(NULL)

