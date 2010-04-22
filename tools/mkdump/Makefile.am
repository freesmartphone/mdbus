NULL =

AUTOMAKE_OPTIONS = subdir-objects
VALAC_ARGS = \
	--vapidir vapi \
	--pkg posix \
	--pkg linux \
	--pkg gio-2.0 \
	--pkg fsobasics-2.0 \
	--pkg config \
	--save-temps \
	--basedir $(top_srcdir)

SUBDIRS = \
	$(NULL)

INCLUDES = \
	-I$(top_srcdir) \
	$(DEPS_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = src/.vala.stamp

sbin_PROGRAMS = mkdump

mkdump_VALASOURCES = \
	src/main.vala \
	$(NULL)

mkdump_SOURCES = \
	$(mkdump_VALASOURCES:.vala=.c) \
	$(NULL)

src/.vala.stamp: $(mkdump_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

mkdump_LDADD = \
	$(DEPS_LIBS) \
	$(NULL)

EXTRA_DIST = \
	MAINTAINERS \
	$(mkdump_VALASOURCES) \
	$(BUILT_SOURCES) \
	$(NULL)

CLEANFILES = \
	src/*.? \
	src/*.l? \
	$(BUILT_SOURCES) \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

MAINTAINERCLEANFILES = aclocal.m4 compile config.guess config.sub \
                       configure depcomp install-sh ltmain.sh     \
                       Makefile.in missing config.h.in            \
                       intltool-extract \
                       intltool-merge \
                       intltool-update \
                       mkinstalldirs \
                       .deps \
                       src/*.c src/*.h \
                       $(NULL)
