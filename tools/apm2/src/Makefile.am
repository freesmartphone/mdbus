include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	-C --vapidir vapi \
        --pkg posix \
        --pkg dbus-glib-1 \
        --save-temps \
        --basedir $(top_srcdir)

INCLUDES = \
	$(DBUS_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

bin_PROGRAMS = apm

apm_VALASOURCES = \
	main.vala \
	$(NULL)

apm_SOURCES = \
	$(apm_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(apm_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@

apm_LDADD = \
	$(DBUS_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(apm_VALASOURCES) \
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
