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

bin_PROGRAMS = mdbus2

mdbus2_VALASOURCES = \
	main.vala \
	$(NULL)

mdbus2_SOURCES = \
	$(mdbus2_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(mdbus2_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@

mdbus2_LDADD = \
	$(DBUS_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(mdbus2_VALASOURCES) \
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
