include $(top_srcdir)/Makefile.decl

NULL =

INCLUDES = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsotdld\" \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsotdld

fsotdld_VALASOURCES = \
	main.vala \
	$(NULL)

fsotdld_SOURCES = \
	$(fsotdld_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsotdld_VALASOURCES)
	$(VALAC) -C --vapidir vapi \
				--pkg posix \
				--pkg gio-2.0 \
				--pkg fsoframework-2.0 \
				--save-temps \
				--basedir $(top_srcdir) $^
	touch $@

fsotdld_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fsotdld_VALASOURCES) \
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
