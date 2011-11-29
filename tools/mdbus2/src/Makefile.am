include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../vapi \
	--pkg posix \
	--pkg readline \
	--pkg dbus-glib-1 \
	--pkg gio-2.0 \
	--save-temps
	--pkg gio-2.0 \
	--enable-experimental

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS = -ggdb -O0
endif

INCLUDES = \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

bin_PROGRAMS = mdbus2

mdbus2_VALASOURCES = \
	main.vala \
	$(NULL)

mdbus2_SOURCES = \
	$(mdbus2_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(mdbus2_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

mdbus2_LDADD = \
	$(LIBREADLINE) \
	$(GLIB_LIBS) \
	$(NULL)

man_MANS = mdbus2.1

EXTRA_DIST += \
	$(mdbus2_VALASOURCES) \
	$(BUILT_SOURCES) \
	$(man_MANS) \
	$(NULL)

CLEANFILES = \
	*.c \
	*.h \
	$(BUILT_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
