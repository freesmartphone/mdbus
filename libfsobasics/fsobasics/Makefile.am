include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(LIBNL_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsobasics\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg linux \
	--pkg libnl-2.0 \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--header fsobasics.h \
	--library fsobasics-2.0

if HAVE_BACKTRACE
VALAC_ARGS += -D HAVE_BACKTRACE
endif

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = fsobasics.vala.stamp

lib_LTLIBRARIES = \
	libfsobasics.la
	$(NULL)

libfsobasics_la_VALASOURCES = \
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
	kernel.vala \
	checksum.vala \
	$(NULL)

libfsobasics_la_SOURCES = \
	fsobasics.vala.stamp \
	$(libfsobasics_la_VALASOURCES:.vala=.c) \
	gcc_libinitexit.c \
	$(NULL)

fsobasicsincludedir = $(includedir)/fsoframework-2.0
fsobasicsinclude_HEADERS = fsobasics.h

fsobasics-2.0.vapi fsobasics.vala.stamp: $(libfsobasics_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libfsobasics_la_LIBADD = \
	$(GLIB_LIBS) \
	$(LIBNL_LIBS) \
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

