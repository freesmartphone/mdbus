include $(top_srcdir)/Makefile.decl

NULL =

INCLUDES = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

bin_PROGRAMS = fsousaged

fsousaged_VALASOURCES = \
	main.vala \
	$(NULL)

fsousaged_SOURCES = \
	$(fsousaged_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsousaged_VALASOURCES)
	$(VALAC) -c --vapidir vapi \
				--pkg posix \
				--pkg gio-2.0 \
				--pkg dbus-glib-1 \
				--pkg fsoframework-2.0 \
				--save-temps \
				--basedir $(top_srcdir) $^
	touch $@

fsousaged_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(fsousaged_VALASOURCES) \
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
