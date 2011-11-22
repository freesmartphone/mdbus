include $(top_srcdir)/Makefile.decl

NULL =

INCLUDES = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsophoned

fsophoned_VALASOURCES = \
	main.vala \
	$(NULL)

fsophoned_SOURCES = \
	$(fsophoned_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsophoned_VALASOURCES)
	$(VALAC) -C --vapidir vapi \
				--pkg posix \
				--pkg gio-2.0 \
				--pkg fsoframework-2.0 \
				--save-temps \
				--basedir $(top_srcdir) $^
	touch $@

fsophoned_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fsophoned_VALASOURCES) \
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
