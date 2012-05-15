include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS =
AM_VALAFLAGS =

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

bin_PROGRAMS = mdbus2
mdbus2_SOURCES = \
	main.vala \
	argument.vala \
	$(NULL)
mdbus2_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--pkg posix \
	--pkg readline \
	--pkg gio-2.0 \
	--save-temps
	--pkg gio-2.0 \
	--enable-experimental \
	$(NULL)
mdbus2_CFLAGS = \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)
mdbus2_LDADD = \
	$(LIBREADLINE) \
	$(GLIB_LIBS) \
	$(NULL)

man_MANS = mdbus2.1

EXTRA_DIST += \
	$(man_MANS) \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
