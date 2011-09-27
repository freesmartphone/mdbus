include $(top_srcdir)/Makefile.decl

NULL =

INCLUDES = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsopreferences\" \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsopreferencesd

fsopreferencesd_VALASOURCES = \
	main.vala \
	$(NULL)

fsopreferencesd_SOURCES = \
	$(fsopreferencesd_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsopreferencesd_VALASOURCES)
	$(VALAC) -C --vapidir $(top_srcdir)/vapi \
				--pkg posix \
				--pkg config \
				--pkg gio-2.0 \
				--pkg fsoframework-2.0 \
				--save-temps \
				--basedir $(top_srcdir) $^
	touch $@

fsopreferencesd_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fsopreferencesd_VALASOURCES) \
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
