include $(top_srcdir)/Makefile.decl

NULL =

INCLUDES = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsolocationd

fsolocationd_VALASOURCES = \
	main.vala \
	$(NULL)

fsolocationd_SOURCES = \
	$(fsolocationd_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsolocationd_VALASOURCES)
	$(VALAC) -C --vapidir vapi \
				--pkg posix \
				--pkg gio-2.0 \
				--pkg dbus-glib-1 \
				--pkg fsoframework-2.0 \
				--save-temps \
				--basedir $(top_srcdir) $^
	touch $@

fsolocationd_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fsolocationd_VALASOURCES) \
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
