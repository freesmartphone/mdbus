include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	-C --vapidir vapi \
        --pkg posix \
        --pkg linux \
        --save-temps \
        --basedir $(top_srcdir)

INCLUDES = \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = mioctl

mioctl_VALASOURCES = \
	main.vala \
	$(NULL)

mioctl_SOURCES = \
	$(mioctl_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(mioctl_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@

mioctl_LDADD = \
	$(DBUS_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(mioctl_VALASOURCES) \
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
