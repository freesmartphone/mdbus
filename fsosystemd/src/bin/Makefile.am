include $(top_srcdir)/Makefile.decl

NULL =

INCLUDES = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsosystemd\" \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsosystemd

fsosystemd_VALASOURCES = \
	main.vala \
	$(NULL)

fsosystemd_SOURCES = \
	$(fsosystemd_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsosystemd_VALASOURCES)
	$(VALAC) -C --vapidir vapi \
				--pkg posix \
				--pkg gio-2.0 \
				--pkg fsoframework-2.0 \
				--save-temps \
				--basedir $(top_srcdir) $^
	touch $@

fsosystemd_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fsosystemd_VALASOURCES) \
	$(fsosystemd_SOURCES) \
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
