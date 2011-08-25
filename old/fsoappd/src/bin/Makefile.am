include $(top_srcdir)/Makefile.decl

NULL =

INCLUDES = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-I$(top_srcdir)/src/lib \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsoappd\" \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsoappd

fsoappd_VALASOURCES = \
	main.vala \
	$(NULL)

fsoappd_SOURCES = \
	$(fsoappd_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsoappd_VALASOURCES)
	$(VALAC) -C --vapidir vapi \
				--pkg posix \
				--pkg gio-2.0 \
				--pkg fsoframework-2.0 \
				--save-temps \
				--basedir $(top_srcdir) $^
	touch $@

fsoappd_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fsoappd_VALASOURCES) \
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
