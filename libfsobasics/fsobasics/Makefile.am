include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsobasics\" \
	-DSYSCONFDIR=\"$(sysconfdir)\" \
	-D_GNU_SOURCE \
	$(NULL)
AM_VALAFLAGS = \
	$(NULL)

if HAVE_BACKTRACE
AM_VALAFLAGS += -D HAVE_BACKTRACE
endif

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

lib_LTLIBRARIES = libfsobasics.la

libfsobasics_la_SOURCES = \
	asyncworker.vala \
	binary.vala \
	inotifier.vala \
	kobjectnotifier.vala \
	libinitexit.vala \
	logger.vala \
	netlinknotifier.vala \
	netlinkutils.vala \
	overlay.vala \
	process.vala \
	smartkeyfile.vala \
	syncasync.vala \
	threading.vala \
	types.vala \
	utilities.vala \
	filehandling.vala \
	stringhandling.vala \
	async.vala \
	kernel.vala \
	checksum.vala \
	object.vala \
	gcc_libinitexit.c \
	$(NULL)

libfsobasics_la_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(LIBNL_CFLAGS) \
	$(NULL)

libfsobasics_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg linux \
	--pkg libnl-3.0 \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg config \
	--pkg misc \
	-D SYSCONFDIR="$(sysconfdir)" \
	--header fsobasics.h \
	--library fsobasics-2.0
	$(NULL)

libfsobasics_la_LIBADD = \
	$(GLIB_LIBS) \
	$(LIBNL_LIBS) \
	$(NULL)
libfsobasics_la_LDFLAGS = \
	$(AM_LDFLAGS) \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)" \
	$(NULL)

fsobasicsincludedir = $(includedir)/fsoframework-2.0
fsobasicsinclude_HEADERS = fsobasics.h

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	fsobasics-2.0.vapi \
	fsobasics-2.0.deps \
	$(NULL)

BUILT_SOURCES = \
	fsobasics.h \
	fsobasics-2.0.vapi \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)

