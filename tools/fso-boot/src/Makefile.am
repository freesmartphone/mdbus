include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../vapi \
	--pkg posix \
	--pkg dbus-glib-1 \
	--save-temps

if WANT_DEBUG
VALAC_ARGS += -D DEBUG
endif

INCLUDES = \
	$(DBUS_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

bin_PROGRAMS = fso-boot

fso-boot_VALASOURCES = \
	main.vala \
	$(NULL)

fso-boot_SOURCES = \
	$(fso-boot_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fso-boot_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

fso-boot_LDADD = \
	$(DBUS_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fso-boot_VALASOURCES) \
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
