include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	$(FSOFRAMEWORK_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

VALAC_ARGS = \
	--vapidir ../vapi \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsoresource-2.0 \
	--pkg fso-glib-1.0 \
	--save-temps \
	--basedir $(top_srcdir)

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsotest

fsotest_VALASOURCES = \
	main.vala \
	fixture.vala \
	wait.vala \
	signalwatcher.vala \
	testutils.vala \
	testmanager.vala \
	testusage.vala \
	testgsm.vala \
	$(NULL)

fsotest_SOURCES = \
	$(fsotest_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsotest_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

fsotest_LDADD = \
	$(FSOFRAMEWORK_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fsotest_VALASOURCES) \
	$(BUILT_SOURCES) \
	$(NULL)

CLEANFILES = \
	*.c \
	*.h \
	$(BUILT_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)

