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

bin_PROGRAMS = fso-alsa

fso_alsa_VALASOURCES = \
	main.vala \
	$(NULL)

fso_alsa_SOURCES = \
	$(fso_alsa_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fso_alsa_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@

fso_alsa_LDADD = \
	$(DBUS_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fso_alsa_VALASOURCES) \
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
