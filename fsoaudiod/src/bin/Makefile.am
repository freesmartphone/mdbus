include $(top_srcdir)/Makefile.decl

NULL =

INCLUDES = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsoaudiod

fsoaudiod_VALASOURCES = \
	main.vala \
	$(NULL)

fsoaudiod_SOURCES = \
	$(fsoaudiod_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsoaudiod_VALASOURCES)
	$(VALAC) -C --vapidir vapi \
				--pkg posix \
				--pkg gio-2.0 \
				--pkg fsoframework-2.0 \
				--save-temps \
				--basedir $(top_srcdir) $^
	touch $@

fsoaudiod_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fsoaudiod_VALASOURCES) \
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
