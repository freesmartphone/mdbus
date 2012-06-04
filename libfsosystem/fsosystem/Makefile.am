include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsosystem\" \
	$(NULL)

AM_VALAFLAGS = \
	$(NULL)

if HAVE_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CFLAGS += -g -ggdb
endif

lib_LTLIBRARIES = libfsosystem.la

libfsosystem_la_SOURCES = \
	modules.vala \
	network.vala \
	filesystem.vala \
	path.vala \
	wakelock.vala \
	$(NULL)

libfsosystem_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg linuxext \
	--header fsosystem.h \
	--library fsosystem-2.0 \
	$(NULL)

libfsosystem_la_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(NULL)

libfsosystem_la_LIBADD = \
	$(GLIB_LIBS) \
	$(NULL)
libfsosystem_la_LDFLAGS = \
	$(AM_LDFLAGS) \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	$(NULL)

fsosystemincludedir = $(includedir)/fsoframework-2.0
fsosysteminclude_HEADERS = fsosystem.h

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsosystem-2.0.vapi \
	fsosystem-2.0.deps \
	$(NULL)

BUILT_SOURCES = \
	fsosystem.h \
	fsosystem-2.0.vapi \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)
