NULL =

AUTOMAKE_OPTIONS = subdir-objects

VALAC_ARGS = \
	--vapidir vapi \
	--pkg posix \
	--pkg gsm0710mux-1.0 \
	--pkg fsobasics-2.0 \
	--pkg dbus-glib-1 \
	--save-temps \
	--basedir $(top_srcdir)

SUBDIRS = \
	data \
	$(NULL)

INCLUDES = \
	$(DEPS_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = src/.vala.stamp

sbin_PROGRAMS = fso-abyss

fso_abyss_VALASOURCES = \
	src/consts.vala \
	src/server.vala \
	src/main.vala \
	$(NULL)

fso_abyss_SOURCES = \
	$(fso_abyss_VALASOURCES:.vala=.c) \
	\
	$(NULL)

src/.vala.stamp: $(fso_abyss_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

fso_abyss_LDADD = \
	$(DEPS_LIBS) \
	$(NULL)

EXTRA_DIST = \
	MAINTAINERS \
	$(fso_abyss_VALASOURCES) \
	src/.vala.stamp \
	$(NULL)

CLEANFILES = \
	$(BUILT_SOURCES) \
	src/*.o src/*.c src/*.h \
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
                       src/*.c src/*.h *~ \
                       $(NULL)
